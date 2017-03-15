require 'spec_helper'

# Not a lot of publically accessible API, test what's there and do a more functional test with EchoServer
RSpec.describe Uninterruptible::Server do
  let(:server_class) { Class.new { include Uninterruptible::Server } }
  let(:server) { server_class.new }

  describe '#handle_request' do
    it 'raises NotImplementedError' do
      expect { server.handle_request(nil) }.to raise_error(NotImplementedError)
    end
  end

  describe "#configure" do
    it 'yields the configuration for the server' do
      expect { |b| server.configure(&b) }.to yield_with_args(Uninterruptible::Configuration)
    end
  end

  describe '#run' do
    it 'raises a configuration error when the server is unconfigured' do
      expect { server.run }.to raise_error(Uninterruptible::ConfigurationError)
    end
  end
end
