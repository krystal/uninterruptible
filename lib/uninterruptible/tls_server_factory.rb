module Uninterruptible
  # Wraps a bound TCP server with an OpenSSL::SSL::SSLServer according to the Uninterruptible::Configuration for
  # this server.
  class TLSServerFactory
    attr_reader :configuration

    def initialize(configuration)
      @configuration = configuration
      check_configuration!
    end

    def wrap_with_tls(tcp_server)
      OpenSSL::SSL::SSLServer.new(tcp_server, ssl_context)
    end

    private

    def ssl_context
      context = OpenSSL::SSL::SSLContext.new
      context.cert = configuration.tls_certificate
      context.key = configuration.tls_key
      context.ssl_version = configuration.tls_version.to_sym
      context
    end

    def check_configuration!
      raise ConfigurationError, "TLS can only be used on TCP servers" unless configuration.bind.start_with?('tcp://')

      empty = %i[tls_certificate tls_key].any? { |config_param| configuration.send(config_param).nil? }
      raise ConfigurationError, "tls_certificate and tls_key must be set to use TLS" if empty
    end
  end
end
