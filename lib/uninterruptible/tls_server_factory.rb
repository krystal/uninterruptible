module Uninterruptible
  # Wraps a bound TCP server with an OpenSSL::SSL::SSLServer according to the Uninterruptible::Configuration for
  # this server.
  class TLSServerFactory
    attr_reader :configuration

    # @param [Uninterruptible::Configuration] configuration Object with valid TLS configuration options
    #
    # @raise [Uninterruptible::ConfigurationError] Correct options are not set for TLS
    def initialize(configuration)
      @configuration = configuration
      check_configuration!
    end

    # Accepts a TCP server, gives it a nice friendly SSLServer wrapper and returns the SSLServer
    #
    # @param [TCPServer] tcp_server Server to be wrapped
    #
    # @return [OpenSSL::SSL::SSLServer] tcp_server with a TLS layer
    def wrap_with_tls(tcp_server)
      server = OpenSSL::SSL::SSLServer.new(tcp_server, ssl_context)
      server.start_immediately = true
      server
    end

    private

    # Build an OpenSSL::SSL::SSLContext object from the configuration passed to the initializer
    #
    # @return [OpenSSL::SSL::SSLContext] SSL context for the server config
    def ssl_context
      context = OpenSSL::SSL::SSLContext.new
      context.cert = OpenSSL::X509::Certificate.new(configuration.tls_certificate)
      context.key = OpenSSL::PKey::RSA.new(configuration.tls_key)
      context.ssl_version = configuration.tls_version.to_sym

      if configuration.verify_client_tls_certificate?
        context.verify_mode = OpenSSL::SSL::VERIFY_PEER | OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
      end
      context.ca_file = configuration.client_tls_certificate_ca if configuration.client_tls_certificate_ca

      context
    end

    # Check the configuration parameters for TLS are correct
    #
    # @raise [Uninterruptible::ConfigurationError] Correct options are not set for TLS
    def check_configuration!
      raise ConfigurationError, "TLS can only be used on TCP servers" unless configuration.bind.start_with?('tcp://')

      empty = %i[tls_certificate tls_key].any? { |config_param| configuration.send(config_param).nil? }
      raise ConfigurationError, "tls_certificate and tls_key must be set to use TLS" if empty
    end
  end
end
