require 'spec_helper'

RSpec.describe Uninterruptible::Binder do
  include EnvironmentalControls

  describe '#new' do
    let(:config) { tcp_configuration }

    it 'parses the bind configuration' do
      binder = described_class.new(config)
      expect(binder.bind_uri).to be_a(URI::Generic)
    end

    it 'raises an error when the bind cannot be parsed' do
      config = "nonsense uri"
      expect { described_class.new(config) }.to raise_error(Uninterruptible::ConfigurationError)
    end
  end

  describe '#bind_to_socket' do
    context 'when given a TCP address' do
      let(:binder) { described_class.new(tcp_configuration) }

      it 'binds to a fresh socket' do
        server = binder.bind_to_socket
        expect(server).to be_a(TCPServer)
        server.close
      end

      it 'rebinds to an existing filedescriptor' do
        # open a socket first so we can bind to it
        existing_server = TCPServer.new(binder.bind_uri.host, binder.bind_uri.port)
        existing_file_descriptor = existing_server.to_i

        within_env(Uninterruptible::SERVER_FD_VAR => existing_file_descriptor.to_s) do
          new_server = binder.bind_to_socket

          expect(new_server).to be_a(TCPServer)
          expect(new_server.to_i).to eq(existing_file_descriptor)

          new_server.close
        end
      end
    end

    context 'when given a UNIX address' do
      let(:binder) { described_class.new(unix_configuration) }

      it 'binds to a fresh socket' do
        server = binder.bind_to_socket
        expect(server).to be_a(UNIXServer)
        server.close
      end

      it 'rebinds to an existing filedescriptor' do
        File.delete(unix_path) if File.exist?(unix_path)
        existing_server = UNIXServer.new(unix_path)
        existing_file_descriptor = existing_server.to_i

        within_env(Uninterruptible::SERVER_FD_VAR => existing_file_descriptor.to_s) do
          new_server = binder.bind_to_socket

          expect(new_server).to be_a(UNIXServer)
          expect(new_server.to_i).to eq(existing_file_descriptor)

          new_server.close
        end
      end
    end

    it 'raises an error when given a non-tcp or unix address' do
      binder = described_class.new("https://google.com")
      expect { binder.bind_to_socket }.to raise_error(Uninterruptible::ConfigurationError)
    end
  end

  def tcp_configuration
    "tcp://127.0.0.1:#{tcp_port}"
  end

  def unix_configuration
    "unix://#{unix_path}"
  end

  def tcp_port
    8004
  end

  def unix_path
    '/tmp/unix_server.sock'
  end
end
