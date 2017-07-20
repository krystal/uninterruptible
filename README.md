# Uninterruptible

Uninterruptible gives you zero downtime restarts for your socket servers with nearly zero effort. Sounds good? Read on.

Small socket servers are great, sometimes you need a quick and efficient way of moving data between servers (or even
processes on the same machine). Restarting these processes can be a bit hairy though, you either need to build your
clients smart enough to keep trying to connect, potentially backing up traffic or you just leave your server and
hope for the best.

You _know_ that you'll need to restart it one day and cross your fingers that you can kill the old one and start the
new one before anyone notices. Not ideal at all.

![Just a quick switch](http://i.imgur.com/aFyJJM6.jpg)

Uninterruptible gives your socket server magic restarting powers. Send your running Uninterruptible server USR1 and
it will start a brand new copy of itself which will immediately start handling new requests while the old server stays
alive until all of it's active connections are complete.

## Basic Usage

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

## Configuration Options

```ruby
echo_server.configure do |config|
  config.start_command = 'ruby echo_server.rb' # *Required* Command to execute to start a new server process
  config.bind = "tcp://0.0.0.0:12345" # *Required* Interface to listen on, falls back to 0.0.0.0 on ENV['PORT']
  config.pidfile_path = 'tmp/pids/echoserver.pid' # Location to write a pidfile, falls back to ENV['PID_FILE']
  config.log_path = 'log/echoserver.log' # Location to write logfile, defaults to STDOUT
  config.log_level = Logger::INFO # Log writing severity, defaults to Logger::INFO
end
```

Uninterruptible supports both TCP and UNIX sockets. To connect to a unix socket simply pass the path in the bind
configuration parameter:

```ruby
echo_server.configure do |config|
  config.bind = "unix:///tmp/echo_server.sock"
end
```

## The Magic

Upon receiving `USR1`, your server will spawn a new copy of itself and pass the file descriptor of the open socket to
the new server. The new server attaches itself to the file descriptor then sends a `TERM` signal to the original
process. The original server stops listening on the socket and shuts itself down once all ongoing requests have
completed.

![Restart Flow](http://i.imgur.com/k8uNP55.png)

## Concurrency

By default, Uninterruptible operates on a very simple one thread per connection concurrency model. If you'd like to use
something more advanced such as a threadpool or an event driven pattern you can define this in your server class.

By overriding `accept_client_connection` you can change how connections are accepted and handled. It is recommended
that you call `process_request` from this method and still implement `handle_request` to do the bulk of the work since
`process_request` tracks the number of active connections to the server.

`accept_client_connection` is called whenever a connection is waiting to be accepted on the socket server.

If you wanted to implement a threadpool to process your requests you could do the following:

```ruby
class EchoServer
  # ...

  def accept_client_connection
    @worker_threads ||= 4.times.map do
      Thread.new { worker_loop }
    end

    threads.each(&:join)
  end

  def worker_loop
    loop do
      client_socket = socket_server.accept
      process_request(client_socket)
    end
  end
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/darkphnx/uninterruptible.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

