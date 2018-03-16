require 'openssl'
require 'ipaddr'

require "uninterruptible/version"
require 'uninterruptible/ssl_extensions'
require 'uninterruptible/configuration'
require 'uninterruptible/binder'
require 'uninterruptible/network_restrictions'
require 'uninterruptible/tls_server_factory'
require 'uninterruptible/server'

# All of the interesting stuff is in Uninterruptible::Server
module Uninterruptible
  class ConfigurationError < StandardError; end

  SERVER_FD_VAR = 'UNINTERRUPTIBLE_SERVER_FD'.freeze
end
