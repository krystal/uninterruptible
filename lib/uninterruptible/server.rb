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
        attr_reader :active_connections, :socket_server, :signal_pipe_r, :signal_pipe_w, :mutex
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

      logger.info "Starting server on #{server_configuration.bind}"

      establish_socket_server
      write_pidfile
      setup_signal_traps
      select_loop
    end

    # @abstract Override this method to process incoming requests. Each request is handled in it's own thread.
    # Socket will be automatically closed after completion.
    #
    # @param [TCPSocket] client_socket Incoming socket from the client
    def handle_request(client_socket)
      raise NotImplementedError
    end

    private

    # Start a blocking loop which awaits new connections before calling #accept_client_connection. Also monitors
    # signal_pipe_r for processing any signals sent to the process.
    def select_loop
      loop do
        readable, = IO.select([socket_server, signal_pipe_r])
        readable.each do |reader|
          if reader == socket_server
            accept_client_connection
          elsif reader == signal_pipe_r
            signal = reader.gets.chomp
            process_signal(signal)
          end
        end
      end
    end

    # Accept a waiting connection. Should only be called when it is known a connection is waiting, from an IO.select
    # loop for example. By default this creates one thread per connection. Override this method to provide a new
    # concurrency model.
    def accept_client_connection
      Thread.start(socket_server.accept_nonblock) do |client_socket|
        process_request(client_socket)
      end
    end

    # Keeps a track of the number of active connections and passes the client connection to #handle_request for the
    # user to do with as they wish. Automatically closes a connection once #handle_request has completed.
    #
    # @param [TCPSocket] client_socket Incoming socket from the client connection
    def process_request(client_socket)
      mutex.synchronize { @active_connections += 1 }
      begin
        client_address = client_socket.peeraddr.last
        if network_restrictions.connection_allowed_from?(client_address)
          logger.debug "Accepting connection from #{client_address}"
          handle_request(client_socket)
        else
          logger.debug "Rejecting connection from #{client_address}"
        end
      ensure
        client_socket.close
        mutex.synchronize { @active_connections -= 1 }
      end
    end

    # Listen (or reconnect) to the bind address and port specified in the config. If FILE_DESCRIPTOR_SERVER_PATH is set
    # in the env, reconnect to that file descriptor.
    def establish_socket_server
      @socket_server = Uninterruptible::Binder.new(server_configuration.bind).bind_to_socket
      # If there's a file descriptor present, take over from a previous instance of this server and kill it off
      kill_parent if ENV[FILE_DESCRIPTOR_SERVER_VAR]

      @socket_server.autoclose = false
      @socket_server.close_on_exec = false

      if server_configuration.tls_enabled?
        @socket_server = Uninterruptible::TLSServerFactory.new(server_configuration).wrap_with_tls(@socket_server)
      end
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

    # Catch TERM and USR1 signals which control the lifecycle of the server. These get written to an internal pipe
    # which will be picked up by the main accept_connection loop and passed to #process_signal
    def setup_signal_traps
      @signal_pipe_r, @signal_pipe_w = IO.pipe

      %w(TERM USR1).each do |signal_name|
        trap(signal_name) do
          @signal_pipe_w.puts(signal_name)
        end
      end
    end

    # When a signal has been caught, it should be passed here for the appropriate action to be taken
    # On TERM begin a graceful shutdown, if a second TERM is received shutdown immediately with an exit code of 1
    # On USR1 begin a hot restart which will bring up a new copy of the server and then shut down the old one
    #
    # @param [String] signal_name Signal to process
    def process_signal(signal_name)
      if signal_name == 'TERM'
        if $shutdown
          logger.info "TERM received again, exiting immediately"
          Process.exit(1) if $shutdown
        else
          logger.info "TERM received, starting graceful shutdown"
          $shutdown = true
          graceful_shutdown
        end
      elsif signal_name == 'USR1'
        logger.info "USR1 received, hot restart in progress"
        hot_restart
      end
    end

    # Stop listening on socket_server, wait until all active connections have finished processing and exit with 0.
    def graceful_shutdown
      socket_server.close unless socket_server.closed?

      until active_connections.zero?
        logger.debug "#{active_connections} connections still active"
        sleep 0.5
      end

      logger.debug "No more active connections. Exiting'"

      Process.exit(0)
    end

    # Start a new copy of this server, maintaining all current file descriptors and env.
    def hot_restart
      # Start a FileDescriptorServer running on a unix socket
      file_descriptor_server = FileDescriptorServer.new(socket_server)

      fork do
        # Let the new server know where to find the file descriptor server
        ENV[FILE_DESCRIPTOR_SERVER_VAR] = file_descriptor_server.socket_path

        Dir.chdir(ENV['APP_ROOT']) if ENV['APP_ROOT']
        ENV.delete('BUNDLE_GEMFILE') # Ensure a fresh bundle is used

        exec("bundle exec #{server_configuration.start_command}")
      end

      # Provide the new server with the file descriptor for @socket_server
      file_descriptor_server.serve_file_descriptor
      file_descriptor_server.close
    end

    def network_restrictions
      @network_restrictions ||= Uninterruptible::NetworkRestrictions.new(server_configuration)
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
