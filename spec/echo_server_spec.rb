require 'spec_helper'

# A functional test of an Uninterruptible::Server, see support/echo_server for server implementation
RSpec.describe "EchoServer" do
  include EchoServerControls

  before(:all) do
    start_echo_server
  end

  after(:all) do
    stop_echo_server
  end

  it "writes a PID file" do
    expect(File.exist?(echo_pid_path)).to be true
  end

  it "starts a TCP server" do
    with_echo_connection do |socket|
      expect(socket).to be_a(TCPSocket)
    end
  end

  it "echoes data sent to it" do
    with_echo_connection do |socket|
      message = "hello world!"
      socket.puts(message)
      rtn_data = socket.gets(message.length)

      expect(rtn_data).to eq(message)
    end
  end

  context "on recieving TERM" do
    after(:each) do
      # Every test in this block should end with the echo server stopped, so start a new one for the next test
      start_echo_server
    end

    it "quits immediately when no connections are active", focus: true do
      Process.kill("TERM", current_echo_pid)
      sleep 0.1 # immediately-ish
      expect(echo_server_running?).to be false
    end

    it "does not quit until all connections are complete" do
      connection_thread = Thread.start do
        with_echo_connection do |socket|
          sleep 1
        end
      end

      # Try to kill immediately, this should fail
      Process.kill("TERM", current_echo_pid)
      expect(echo_server_running?).to be true

      # Should quit after the last process has disconnected
      connection_thread.join
      expect(echo_server_running?).to be false
    end

    it "quits immediately after receiving a second TERM" do
      Thread.start do
        with_echo_connection do |socket|
          sleep 1
        end
      end

      # First TERM waits for the connection to finish
      Process.kill("TERM", current_echo_pid)
      expect(echo_server_running?).to be true

      # Second TERN bails out immediately
      Process.kill("TERM", current_echo_pid)
      sleep 0.1 # immediately-ish
      expect(echo_server_running?).to be false
    end
  end

  context "on receiving USR1" do
    it 'spawns a new copy of the server' do
      original_pid = current_echo_pid
      Process.kill('USR1', original_pid)

      wait_for_pid_change

      expect(current_echo_pid).not_to eq(original_pid)
      expect(pid_running?(current_echo_pid)).to be true
    end

    it 'terminates the original server' do
      original_pid = current_echo_pid
      Process.kill('USR1', original_pid)

      wait_for_pid_change

      expect(pid_running?(original_pid)).to be false
    end

    it 'updates the pid file' do
      original_pid = current_echo_pid
      Process.kill('USR1', original_pid)

      wait_for_pid_change

      new_pid = File.read(echo_pid_path)
      expect(new_pid).not_to eq(original_pid)
    end
  end

  # Open a connection to the running echo server and yield the socket in the block. Autocloses once finished.
  def with_echo_connection
    socket = TCPSocket.new("localhost", echo_port)
    yield socket if block_given?
  ensure
    socket.close
  end

  def echo_server_running?
    pid_running?(current_echo_pid)
  end

  def pid_running?(pid)
    # Use waitpid to check on child processes, getpgid reports incorrectly for them
    Process.waitpid(pid, Process::WNOHANG).nil?
  rescue Errno::ECHILD
    # Use Process.getpgid if it's not a child process we're looking for
    begin
      Process.getpgid(pid)
      true
    rescue Errno::ESRCH
      false
    end
  end

  # Wait for the echo server pidfile to change.
  #
  # @param [Integer] timeout Timeout in seconds
  def wait_for_pid_change(timeout = 5)
    starting_pid = current_echo_pid
    timeout_tries = timeout * 2 # half second intervals

    tries = 0
    while current_echo_pid == starting_pid && tries < timeout_tries
      tries += 1
      sleep 0.5
    end

    raise "Timeout waiting for PID change" if timeout_tries == tries
  end
end
