require "uninterruptible/version"
require 'uninterruptible/configuration'
require 'uninterruptible/server'

# All of the interesting stuff is in Uninterruptible::Server
module Uninterruptible
  class ConfigurationError < StandardError; end
end
