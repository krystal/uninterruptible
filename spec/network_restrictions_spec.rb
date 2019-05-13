require 'spec_helper'

RSpec.describe Uninterruptible::NetworkRestrictions do
  let(:config) { simple_configuration }

  describe '.new' do
    it 'accepts a server configuration' do
      network_restrictions = described_class.new(config)

      expect(network_restrictions.configuration).to eq(config)
    end

    it 'raises a configuration error if the configuration is not for a TCP server and restrictions have been made' do
      config.bind = "unix:///tmp/testsocket.sock"
      config.allowed_networks = allowed_networks

      expect { described_class.new(config) }.to raise_error(Uninterruptible::ConfigurationError)
    end
  end

  describe '#connection_allowed_from?' do
    it 'returns true if now allowed networks are configured' do
      network_restrictions = described_class.new(config)
      expect(network_restrictions.connection_allowed_from?('127.0.0.1')).to be true
    end

    describe 'when allowed networks are configured' do
      let(:config) { restricted_configuration }
      let(:network_restrictions) { described_class.new(config) }

      it 'returns true if the connecting address is in the included networks' do
        allowed_addresses.each do |allowed_address|
          expect(network_restrictions.connection_allowed_from?(allowed_address)).to be true
        end
      end

      it 'returns false if the connecting address is not in the included networks' do
        disallowed_addresses.each do |disallowed_addresses|
          expect(network_restrictions.connection_allowed_from?(disallowed_addresses)).to be false
        end
      end
    end
  end

  def allowed_networks
    ['127.0.0.0/8', '192.168.23.0/24', '2001:db8::/32']
  end

  def allowed_addresses
    ['127.0.0.1', '127.254.254.254', '192.168.23.1', '192.168.23.254', '2001:db8::12']
  end

  def disallowed_addresses
    ['8.8.8.8', '126.0.0.1', '192.168.0.1', '192.168.24.254', '2001:db7::12']
  end

  def simple_configuration
    Uninterruptible::Configuration.new.tap do |config|
      config.bind = "tcp://127.0.0.1:6626"
    end
  end

  def restricted_configuration
    Uninterruptible::Configuration.new.tap do |config|
      config.bind = "tcp://127.0.0.1:6626"
      config.allowed_networks = allowed_networks
    end
  end
end
