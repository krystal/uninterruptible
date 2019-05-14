require 'openssl'
require 'ipaddr'

require "uninterruptible/version"
require 'uninterruptible/ssl_extensions'
require 'uninterruptible/configuration'
require 'uninterruptible/binder'
require 'uninterruptible/file_descriptor_server'
require 'uninterruptible/network_restrictions'
require 'uninterruptible/tls_server_factory'
require 'uninterruptible/server'

# All of the interesting stuff is in Uninterruptible::Server
module Uninterruptible
  class ConfigurationError < StandardError; end

  FILE_DESCRIPTOR_SERVER_VAR = 'FILE_DESCRIPTOR_SERVER_PATH'.freeze
end
