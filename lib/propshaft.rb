require "active_support"
require "active_support/core_ext/module/attribute_accessors"

module Propshaft
  mattr_accessor :logger
end

require "propshaft/assembly"
require "propshaft/helper"
require "propshaft/railtie"
