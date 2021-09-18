require "rails"
require "rails/railtie"
require "active_support/ordered_options"

require "propshaft/load_path"
require "propshaft/server"

module Propshaft
  class Railtie < ::Rails::Railtie
    config.assets = ActiveSupport::OrderedOptions.new
    config.assets.paths    = []
    config.assets.precompile = [] # Compatibility shim
    config.assets.prefix   = "/assets"
    config.assets.manifest = nil

    config.after_initialize do |app|
      app.assets = Propshaft::LoadPath.new(app.config.assets.paths)
      app.routes.prepend do
        mount Propshaft::Server.new(app.assets) => app.config.assets.prefix
      end
    end
  end
end
