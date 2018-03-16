module Uninterruptible
  class NetworkRestrictions
    attr_reader :configuration

    # @param [Uninterruptible::Configuration] configuration Object with allowed_networks configuration
    def initialize(configuration)
      @configuration = configuration
      check_configuration!
    end

    # Should the incoming connection be allowed to connect?
    #
    # @param [TCPSocket] client_socket Incoming socket from the client connection
    def connection_allowed_from?(client_address)
      return true unless configuration.block_connections?
      allowed_networks.any? { |allowed_network| allowed_network.include?(client_address) }
    end

    private

    # Parse the list of allowed networks from the configuration and turn them into IPAddr objects
    #
    # @return [Array<IPAddr>] Parsed list of IP networks
    def allowed_networks
      @allowed_networks ||= configuration.allowed_networks.map do |network|
        IPAddr.new(network)
      end
    end

    # Check the configuration parameters for network restrictions
    #
    # @raise [Uninterruptible::ConfigurationError] Correct options are not set for network restrictions
    def check_configuration!
      unless configuration.bind.start_with?('tcp://')
        raise ConfigurationError, "Network restrictions can only be used on TCP servers"
      end
    end
  end
end
