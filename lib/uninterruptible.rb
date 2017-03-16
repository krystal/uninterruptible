require "uninterruptible/version"
require 'uninterruptible/configuration'
require 'uninterruptible/binder'
require 'uninterruptible/server'

# All of the interesting stuff is in Uninterruptible::Server
module Uninterruptible
  class ConfigurationError < StandardError; end

  SERVER_FD_VAR = 'UNINTERRUPTIBLE_SERVER_FD'.freeze
end
