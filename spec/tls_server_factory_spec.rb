require 'spec_helper'

RSpec.describe Uninterruptible::TLSServerFactory do
  include TLSConfiguration

  describe '.new' do
    it 'accepts an Uninterruptible configuration' do
      factory = described_class.new(valid_tls_configuration)
      expect(factory).to be_a(described_class)
    end

    it 'raises an error if the configuration is for a unix server' do
      config = valid_tls_configuration
      config.bind = "unix:///tmp/mysocket.sock"

      expect { described_class.new(config) }.to raise_error(Uninterruptible::ConfigurationError)
    end

    it 'raises an error if the tls_key is not set' do
      config = valid_tls_configuration
      config.tls_key = nil

      expect { described_class.new(config) }.to raise_error(Uninterruptible::ConfigurationError)
    end

    it 'raises an error if the tls_certificate is not set' do
      config = valid_tls_configuration
      config.tls_certificate = nil

      expect { described_class.new(config) }.to raise_error(Uninterruptible::ConfigurationError)
    end
  end

  describe '#wrap_with_tls' do
    let(:factory) { described_class.new(valid_tls_configuration) }
    let(:tcp_server) { TCPServer.new('127.0.0.1', 6626) }

    it 'returns an OpenSSL::SSL::SSLServer' do
      expect(factory.wrap_with_tls(tcp_server)).to be_a(OpenSSL::SSL::SSLServer)
      tcp_server.close
    end
  end
end
