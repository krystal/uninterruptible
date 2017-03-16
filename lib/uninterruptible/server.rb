require 'socket'
require 'logger'

module Uninterruptible
  # The meat and potatoes of uninterruptible, include this in your server, configure it and override #handle_request.
  #
  # Calling #run will listen on the configured port and start a blocking server. Send that server signal USR1 to
  # begin a hot-restart and TERM to start a graceful shutdown. Send TERM again for an immediate shutdown.
  #
  # @example
  #   class HelloServer
  #     include Uninterruptible::Server
  #
  #     def handle_request(client_socket)
  #       name = client_socket.read
  #       client_socket.write("Hello #{name}!")
  #     end
  #   end
  #
  # To then use this server, call #configure on it to set the port and restart command, then call #run to start.
  #
  # @example
  #   hello_server = HelloServer.new
  #   hello_server.configure do |config|
  #     config.start_command = 'rake my_app:hello_server'
  #     config.port = 7000
  #   end
  #   hello_server.run
  #
  module Server
    def self.included(base)
      base.class_eval do
        attr_reader :active_connections, :socket_server, :mutex
      end
    end

    # Configure the server, see {Uninterruptible::Configuration} for full options.
    #
    # @yield [Uninterruptible::Configuration] the current configuration for this server instance
    #
    # @return [Uninterruptible::Configuration] the current configuration (after yield)
    def configure
      yield server_configuration if block_given?
      server_configuration
    end

    # Starts the server, this is a blocking operation. Bind to the address and port specified in the configuration,
    # write the pidfile (if configured) and start accepting new connections for processing.
    def run
      @active_connections = 0
      @mutex = Mutex.new

      logger.info "Starting server on #{server_configuration.bind_address}:#{server_configuration.bind_port}"

      establish_socket_server
      write_pidfile
      setup_signal_traps
      accept_connections
    end

    # @abstract Override this method to process incoming requests. Each request is handled in it's own thread.
    # Socket will be automatically closed after completion.
    #
    # @param [TCPSocket] client_socket Incoming socket from the client
    def handle_request(client_socket)
      raise NotImplementedError
    end

    private

    # Start a blocking loop which accepts new connections and hands them off to #process_request. Override this to
    # use a different concurrency pattern, a thread per connection is the default.
    def accept_connections
      loop do
        Thread.start(socket_server.accept) do |client_socket|
          logger.debug "Accepted connection from #{client_socket.peeraddr.last}"
          process_request(client_socket)
        end
      end
    end

    # Keeps a track of the number of active connections and passes the client connection to #handle_request for the
    # user to do with as they wish. Automatically closes a connection once #handle_request has completed.
    #
    # @param [TCPSocket] client_socket Incoming socket from the client connection
    def process_request(client_socket)
      mutex.synchronize { @active_connections += 1 }
      begin
        handle_request(client_socket)
      ensure
        client_socket.close
        mutex.synchronize { @active_connections -= 1 }
      end
    end

    # Listen (or reconnect) to the bind address and port specified in the config. If socket_server_FD is set in the env,
    # reconnect to that file descriptor. Once @socket_server is set, write the file descriptor ID to the env.
    def establish_socket_server
      @socket_server = Uninterruptible::Binder.new(server_configuration.bind).bind_to_socket
      # If there's a file descriptor present, take over from a previous instance of this server and kill it off
      kill_parent if ENV[SERVER_FD_VAR]

      @socket_server.autoclose = false
      @socket_server.close_on_exec = false

      ENV[SERVER_FD_VAR] = @socket_server.to_i.to_s
    end

    # Send a TERM signal to the parent process. This will be called by a newly spawned server if it has been started
    # by another instance of this server.
    def kill_parent
      logger.debug "Killing parent process #{Process.ppid}"
      Process.kill('TERM', Process.ppid)
    end

    # Write the current pid out to pidfile_path if configured
    def write_pidfile
      return unless server_configuration.pidfile_path

      logger.debug "Writing pid to #{server_configuration.pidfile_path}"
      File.write(server_configuration.pidfile_path, Process.pid.to_s)
    end

    # Catch TERM and USR1 signals which control the lifecycle of the server.
    def setup_signal_traps
      # On TERM begin a graceful shutdown, if a second TERM is received shutdown immediately with an exit code of 1
      Signal.trap('TERM') do
        Process.exit(1) if $shutdown

        $shutdown = true
        graceful_shutdown
      end

      # On USR1 begin a hot restart
      Signal.trap('USR1') do
        hot_restart
      end
    end

    # Stop listening on socket_server, wait until all active connections have finished processing and exit with 0.
    def graceful_shutdown
      socket_server.close unless socket_server.closed?

      until active_connections.zero?
        sleep 0.5
      end

      Process.exit(0)
    end

    # Start a new copy of this server, maintaining all current file descriptors and env.
    def hot_restart
      fork do
        Dir.chdir(ENV['APP_ROOT']) if ENV['APP_ROOT']
        ENV.delete('BUNDLE_GEMFILE') # Ensure a fresh bundle is used
        exec("bundle exec --keep-file-descriptors #{server_configuration.start_command}", :close_others => false)
      end
    end

    # The current configuration of this server
    #
    # @return [Uninterruptible::Configuration] Current or new configuration if unset.
    def server_configuration
      @server_configuration ||= Uninterruptible::Configuration.new
    end

    def logger
      @logger ||= begin
        log = Logger.new(server_configuration.log_path)
        log.level = server_configuration.log_level
        log
      end
    end
  end
end
