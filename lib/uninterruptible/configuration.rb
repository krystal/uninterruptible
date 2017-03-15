module Uninterruptible
  # Configuration parameters for an individual instance of a server.
  #
  # See {Server#configure} for usage instructions.
  class Configuration
    attr_writer :bind_port, :bind_address, :pidfile_path, :start_command

    # Available TCP Port for the server to bind to (required).
    def bind_port
      @bind_port || ENV["PORT"] || raise ConfigurationError, "You must configure a bind_port"
    end

    # Address to bind the server to (defaults to +::+)
    def bind_address
      @bind_address || ENV["BIND_ADDRESS"] || "::"
    end

    # Command that should be used to reexecute the server. Note that +bundle exec+ will be automatically added.
    #
    # @example
    #   rake app:run_server
    def start_command
      @start_command || raise ConfigurationError, "You must configure a start_command"
    end

    # Location to write the pid of the current server to. If blank pidfile will not be written.
    def pidfile_path
      @pidfile_path
    end
  end
end
