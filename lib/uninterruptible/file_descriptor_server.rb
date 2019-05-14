require 'tmpdir'
require 'socket'

module Uninterruptible
  class FileDescriptorServer
    attr_reader :io_object, :socket_server

    # Creates a new FileDescriptorServer and starts a listenting socket server
    #
    # @param [IO] Any IO object that will be shared by this server
    def initialize(io_object)
      @io_object = io_object

      start_socket_server
    end

    # @return [String] Location on disk where socket server is listening
    def socket_path
      @socket_path ||= File.join(socket_directory, 'file_descriptor_server.sock')
    end

    # Accept the next client connection and send it the file descriptor
    #
    # @raise [RuntimeError] Raises a runtime error if the socket server is closed
    def serve_file_descriptor
      raise "File descriptor server has been closed" if socket_server.closed?

      client = socket_server.accept
      client.send_io(io_object)
      client.close
    end

    # Close the socket server and tidy up any created files
    def close
      socket_server.close

      File.delete(socket_path)
      Dir.rmdir(socket_directory)
    end

    private

    def socket_directory
      @socket_directory ||= Dir.mktmpdir('uninterruptible-')
    end

    def start_socket_server
      @socket_server = UNIXServer.new(socket_path)
    end
  end
end
