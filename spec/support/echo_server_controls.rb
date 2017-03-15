module EchoServerControls
  def start_echo_server
    cleanup_echo_server

    fork do
      exec({ "PORT" => echo_port.to_s, "PID_FILE" => echo_pid_path }, "bundle exec spec/support/echo_server")
    end

    # Wait for the pidfile to appear so we know the server is started
    sleep 0.5 until File.exist?(echo_pid_path)
  end

  def stop_echo_server
    Process.kill("TERM", current_echo_pid)
    cleanup_echo_server
  end

  def echo_port
    6789
  end

  def current_echo_pid
    File.read(echo_pid_path).to_i
  end

  def echo_pid_path
    File.expand_path("../echo_server.pid", __FILE__)
  end

  def cleanup_echo_server
    File.delete(echo_pid_path) if File.exist?(echo_pid_path)
  end
end
