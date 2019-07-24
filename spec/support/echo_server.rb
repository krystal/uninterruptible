#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'uninterruptible'

# Simple server, writes back  what it reads
class EchoServer
  include Uninterruptible::Server

  def handle_request(client_socket)
    data_to_echo = client_socket.gets
    client_socket.puts(data_to_echo)
  end
end
