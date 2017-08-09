# Easy access to tls configuration parameters
module TLSConfiguration
  def valid_tls_configuration
    Uninterruptible::Configuration.new.tap do |config|
      config.bind = "tcp://127.0.0.1:6626"
      config.tls_key = tls_key
      config.tls_certificate = tls_certificate
    end
  end

  def tls_key
    File.read(File.expand_path('../tls_key.pem', __FILE__))
  end

  def tls_certificate
    File.read(File.expand_path('../tls_cert.pem', __FILE__))
  end
end
