require "active_support"
require "active_support/core_ext/module/attribute_accessors"
require "logger"

module Propshaft
  mattr_accessor :logger, default: Logger.new(STDOUT)
end

require "propshaft/assembly"
require "propshaft/errors"
require "propshaft/helper"
require "propshaft/railtie"
