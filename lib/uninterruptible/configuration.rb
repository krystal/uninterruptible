module Uninterruptible
  # Configuration parameters for an individual instance of a server.
  #
  # See {Server#configure} for usage instructions.
  class Configuration
    AVAILABLE_SSL_VERSIONS = %w[TLSv1_1 TLSv1_2].freeze

    attr_writer :bind, :bind_port, :bind_address, :pidfile_path, :start_command, :log_path, :log_level, :tls_version,
      :tls_key, :tls_certificate

    # Available TCP Port for the server to bind to (required). Falls back to environment variable PORT if set.
    #
    # @return [Integer] Port number to bind to
    def bind_port
      port = (@bind_port || ENV["PORT"])
      raise ConfigurationError, "You must configure a bind_port" if port.nil?
      port.to_i
    end

    # Address to bind the server to (defaults to +0.0.0.0+).
    def bind_address
      @bind_address || "0.0.0.0"
    end

    # URI to bind to, falls back to tcp://bind_address:bind_port if unset
    def bind
      @bind || "tcp://#{bind_address}:#{bind_port}"
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

    # TLS version to use for the connection. Must be one of +Uninterruptible::Configuration::AVAILABLE_SSL_VERSIONS+
    # If unset, connection will be unencrypted.
    def tls_version
      version = (@tls_version || ENV['TLS_VERSION'])
      return if version.nil?

      unless AVAILABLE_SSL_VERSIONS.include?(version)
        raise ConfigurationError, "Please ensure tls_version is one of #{AVAILABLE_SSL_VERSIONS.join(', ')}"
      end

      version
    end

    # Private key used for encrypting TLS connection. If environment variable TLS_KEY is set, attempt to read from a
    # file at that location.
    def tls_key
      @tls_key || (ENV['TLS_KEY'] ? File.read(ENV['TLS_KEY']) : nil)
    end

    # Certificate used for authenticating TLS connection. If environment variable TLS_CERTIFICATE is set, attempt to
    # read from a file at that location
    def tls_certificate
      @tls_certificate || (ENV['TLS_CERTIFICATE'] ? File.read(ENV['TLS_CERTIFICATE']) : nil)
    end
  end
end
