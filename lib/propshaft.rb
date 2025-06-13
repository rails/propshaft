require "active_support"
require "active_support/core_ext/module/attribute_accessors"
require "active_support/core_ext/module/delegation"
require "logger"

module Propshaft
  mattr_accessor :logger, default: Logger.new(STDOUT)
end

require "propshaft/assembly"
require "propshaft/errors"
require "propshaft/helper"
require "propshaft/railtie" if defined?(Rails::Railtie)
