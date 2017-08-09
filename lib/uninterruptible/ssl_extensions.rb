# Augment some parts of OpenSSL::SSL::SSLServer from stdlib for extra functionality
module OpenSSL
  module SSL
    # Extend this module from stdlib to delegate additional methods to the underlying TCP transport when wrapping
    # with an OpenSSL::SSL::SSLServer
    module SocketForwarder
      # Fetch the file descriptor ID from the underlying transport
      def to_i
        to_io.to_i
      end
    end

    # Extend OpenSSL::SSL::SSLServer to implement accept_nonblock (only #accept is implemented by stdlib)
    class SSLServer
      def accept_nonblock
        sock = @svr.accept_nonblock

        begin
          ssl = OpenSSL::SSL::SSLSocket.new(sock, @ctx)
          ssl.sync_close = true
          ssl.accept if @start_immediately
          ssl
        rescue SSLError => ex
          sock.close
          raise ex
        end
      end
    end
  end
end
