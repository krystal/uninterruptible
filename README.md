# Uninterruptible

Uninterruptible gives you zero downtime restarts for your TCP servers with nearly zero effort. Sounds good? Read on...

Small socket servers are great, sometimes you need a quick and efficient way of moving data between servers (or even
processes on the same machine). Restarting these processes can be a bit hairy though, you either need to build your
clients smart enough to keep trying to connect, potentially backing up traffic or you just leave your server and
hope for the best.

You _know_ that you'll need to restart it one day and cross your fingers that you can kill the old one and start the
new one before anyone notices. Not ideal at all.

![Just a quick switch](http://imgur.com/a/ax5X9)

Uninterruptible gives your socket server magic restarting powers. Using the magnificence of file descriptors we can
pass the open socket to a new copy of the server before the old one goes away.

![INSERT MAGIC DIAGRAM HERE]()

## Usage

Add this line to your application's Gemfile:

```ruby
gem 'uninterruptible'
```

To build your server all you need to do is include `Uninterruptible::Server` and implement `handle_request`. Let's build
a simple echo server:

```ruby
# echo_server.rb
class EchoServer
  include Uninterruptible::Server

  def handle_request(client_socket)
    received_data = client_socket.gets
    client_socket.puts(received_data)
  end
end
```

To turn this into a running server you only need to configure a port to listen on and the command used to start the
server and call `run`:

```ruby
echo_server = EchoServer.new
echo_server.configure do |config|
  config.bind_port = 6789
  config.start_command = 'ruby echo_server.rb'
end
echo_server.run
```

To restart the server just send `USR1`, a new server will start listening on your port, the old one will quit once it's
finished processing all of it's existing connections. To kill the server (allowing for all connections to finish) call
`TERM`.

Full configuration options are as follows:

```ruby
echo_server.configure do |config|
  config.start_command = 'ruby echo_server.rb' # *Required* Command to execute to start a new server process
  config.bind_port = 6789 # *Required* Port to listen on, falls back to ENV['PORT']
  config.bind_address = '::' # Address to listen on
  config.pidfile_path = 'tmp/pids/echoserver.pid' # Location to write a pidfile, falls back to ENV['PID_FILE']
  config.log_path = 'log/echoserver.log' # Location to write logfile, defaults to STDOUT
  config.log_level = Logger::INFO # Log writing severity, defaults to Logger::INFO
end

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/darkphnx/uninterruptible.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

