module Propshaft
  class Railtie < ::Rails::Railtie
    config.assets = OrderedOptions.new
    config.assets.paths    = []
    config.assets.prefix   = "/assets"
    config.assets.manifest = nil
  end
end