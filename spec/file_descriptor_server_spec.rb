require 'spec_helper'

RSpec.describe Uninterruptible::FileDescriptorServer do
  let(:io_object) { build_io_object }
  let(:file_descriptor_server) { described_class.new(io_object) }

  describe '.new' do
    it 'accepts an IO object to send to a client' do
      file_descriptor_server = described_class.new(io_object)

      expect(file_descriptor_server.io_object).to eq(io_object)
    end

    it 'starts a unix socket server' do
      file_descriptor_server = described_class.new(io_object)

      expect(File.socket?(file_descriptor_server.socket_path)).to be true
    end
  end

  describe '#socket_path' do
    it 'returns the path where the socket server is running' do
      socket_path = file_descriptor_server.socket_path

      expect(File.socket?(socket_path)).to be true
    end
  end

  describe '#socket_server' do
    it 'returns the started unix socket server' do
      socket_server = file_descriptor_server.socket_server

      expect(socket_server).to be_a(UNIXServer)
    end
  end

  describe '#serve_file_descriptor', focus: true do
    it 'sends the file descriptor of the IO object to the next client to connect' do
      socket_path = file_descriptor_server.socket_path

      client_thread = Thread.new do
        socket = UNIXSocket.new(socket_path)
        received_io = socket.recv_io
        socket.close
        received_io
      end

      file_descriptor_server.serve_file_descriptor

      # The received_io will infact have a new file descriptor, pointing to the same place not sure how we test
      # they're exactly the same
      expect(client_thread.value).to be_a(IO)
    end

    it 'raises an error if the socket server is closed' do
      file_descriptor_server.close

      expect { file_descriptor_server.serve_file_descriptor }.to raise_error(RuntimeError)
    end
  end

  describe '#close' do
    it 'closes the socket server' do
      file_descriptor_server.close

      expect(file_descriptor_server.socket_server.closed?).to be true
    end

    it 'removes the path on the file system' do
      socket_path = file_descriptor_server.socket_path

      file_descriptor_server.close

      expect(File.exist?(socket_path)).to be false
    end
  end

  private

  def build_io_object
    _, w_pipe = IO.pipe
    w_pipe
  end
end
