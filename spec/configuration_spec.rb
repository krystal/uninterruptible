require 'spec_helper'

RSpec.describe Uninterruptible::Configuration do
  include EnvironmentalControls

  let(:configuration) { described_class.new }

  describe "#bind" do
    it 'falls back to a TCP address with #bind_address and #bind_port' do
      configuration.bind_port = 1024
      configuration.bind_address = '127.0.0.2'

      expect(configuration.bind).to eq('tcp://127.0.0.2:1024')
    end

    it 'returns the value set by #bind=' do
      configuration.bind = "unix:///tmp/server.sock"
      expect(configuration.bind).to eq("unix:///tmp/server.sock")
    end
  end

  describe "#bind_port" do
    it "falls back to PORT in ENV when unset" do
      within_env("PORT" => "1000") do
        expect(configuration.bind_port).to eq(1000)
      end
    end

    it "raises an exception when no port is set" do
      expect { configuration.bind_port }.to raise_error(Uninterruptible::ConfigurationError)
    end

    it "returns the value set by bind_port=" do
      # PORT should be ignored as it is superceded by bind_port=
      within_env("PORT" => "1000") do
        configuration.bind_port = 1001
        expect(configuration.bind_port).to eq(1001)
      end
    end
  end

  describe "#bind_address" do
    it 'defaults to 0.0.0.0 if unset' do
      expect(configuration.bind_address).to eq('0.0.0.0')
    end

    it 'returns the value set by bind_address=' do
      configuration.bind_address = '127.0.0.1'
      expect(configuration.bind_address).to eq('127.0.0.1')
    end
  end

  describe "#pidfile_path" do
    it 'falls back to PID_FILE in ENV whjen unset' do
      within_env("PID_FILE" => "/tmp/server.pid") do
        expect(configuration.pidfile_path).to eq("/tmp/server.pid")
      end
    end

    it 'returns the value set by pidfile_path=' do
      # PID_FILE should be ignored since it is superceded by pidfile_path=
      within_env("PID_FILE" => "/tmp/server.pid") do
        configuration.pidfile_path = '/tmp/server2.pid'
        expect(configuration.pidfile_path).to eq("/tmp/server2.pid")
      end
    end
  end

  describe "#start_command" do
    it 'returns the value set by start_command=' do
      configuration.start_command = 'rake myapp:run'
      expect(configuration.start_command).to eq('rake myapp:run')
    end

    it 'raises an exception when unset' do
      expect { configuration.start_command }.to raise_error(Uninterruptible::ConfigurationError)
    end
  end

  describe '#log_path' do
    it 'returns the value set by log_path=' do
      configuration.log_path = 'log/server.log'
      expect(configuration.log_path).to eq('log/server.log')
    end

    it 'defaults to STDOUT when unset' do
      expect(configuration.log_path).to eq(STDOUT)
    end
  end

  describe "#log_level" do
    it 'returns the value set by log_level=' do
      configuration.log_level = Logger::FATAL
      expect(configuration.log_level).to eq(Logger::FATAL)
    end

    it 'defaults to Logger::INFO when unset' do
      expect(configuration.log_level).to eq(Logger::INFO)
    end
  end

  describe "#tls_version" do
    it 'returns the value set by #tls_version=' do
      within_env("TLS_VERSION" => 'NOTVERSION') do
        configuration.tls_version = "TLSv1_2"
        expect(configuration.tls_version).to eq("TLSv1_2")
      end
    end

    it 'falls back to TLS_VERSION in env when unset' do
      within_env("TLS_VERSION" => 'TLSv1_1') do
        expect(configuration.tls_version).to eq("TLSv1_1")
      end
    end

    it 'returns nil when unset' do
      expect(configuration.tls_version).to be_nil
    end

    it "raises an error if the version is not approved" do
      configuration.tls_version = "SSLv3"
      expect { configuration.tls_version }.to raise_error(Uninterruptible::ConfigurationError)
    end
  end

  describe '#tls_key' do
    it 'returns the value set by #tls_key=' do
      within_env("TLS_KEY" => 'dummypath') do
        configuration.tls_key = "BEGIN PRIVATE KEY"
        expect(configuration.tls_key).to eq("BEGIN PRIVATE KEY")
      end
    end

    it 'falls back to reading a file located at TLS_KEY in ENV' do
      tempfile = Tempfile.new('test-tls-key')
      tempfile.write("BEGIN PRIVATE KEY FILE")
      tempfile.close

      within_env("TLS_KEY" => tempfile.path) do
        expect(configuration.tls_key).to eq("BEGIN PRIVATE KEY FILE")
      end

      tempfile.unlink
    end

    it 'returns nil when unset' do
      expect(configuration.tls_key).to be_nil
    end
  end

  describe '#tls_certificate' do
    it 'returns the value set by #tls_certificate=' do
      within_env("TLS_CERTIFICATE" => 'dummy_path') do
        configuration.tls_certificate = "BEGIN CERTIFICATE"
        expect(configuration.tls_certificate = "BEGIN CERTIFICATE")
      end
    end

    it 'falls back to reading a file located at TLS_CERTIFICATE in ENV' do
      tempfile = Tempfile.new('test-tls-cert')
      tempfile.write("BEGIN CERTIFICATE FILE")
      tempfile.close

      within_env("TLS_CERTIFICATE" => tempfile.path) do
        expect(configuration.tls_certificate).to eq("BEGIN CERTIFICATE FILE")
      end

      tempfile.unlink
    end

    it 'returns nil when unset' do
      expect(configuration.tls_certificate).to be_nil
    end
  end
end
