module Uninterruptible
  # Configuration parameters for an individual instance of a server.
  #
  # See {Server#configure} for usage instructions.
  class Configuration
    attr_writer :bind_port, :bind_address, :pidfile_path, :start_command, :log_path, :log_level

    # Available TCP Port for the server to bind to (required). Falls back to environment variable PORT if set.
    #
    # @return [Integer] Port number to bind to
    def bind_port
      port = (@bind_port || ENV["PORT"])
      raise ConfigurationError, "You must configure a bind_port" if port.nil?
      port.to_i
    end

    # Address to bind the server to (defaults to +::+).
    def bind_address
      @bind_address || "::"
    end

    # Location to write the pid of the current server to. If blank pidfile will not be written. Falls back to
    # environment variable PID_FILE if set.
    def pidfile_path
      @pidfile_path || ENV["PID_FILE"]
    end

    # Command that should be used to reexecute the server (required). Note: +bundle exec+ will be automatically added.
    #
    # @example
    #   rake app:run_server
    def start_command
      raise ConfigurationError, "You must configure a start_command" unless @start_command
      @start_command
    end

    # Where should log output be written to? (defaults to STDOUT)
    def log_path
      @log_path || STDOUT
    end

    # Severity of entries written to the log, should be one of Logger::Severity (default Logger::INFO)
    def log_level
      @log_level || Logger::INFO
    end
  end
end
