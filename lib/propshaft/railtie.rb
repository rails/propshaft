require "rails"
require "rails/railtie"
require "active_support/ordered_options"

module Propshaft
  class Railtie < ::Rails::Railtie
    config.assets = ActiveSupport::OrderedOptions.new
    config.assets.paths   = []
    config.assets.prefix  = "/assets"

    # Compatibility shiming
    config.assets.precompile = []

    config.after_initialize do |app|
      config.assets.manifest_path =
        Rails.root.join("public/assets/.manifest.json")

      config.assets.output_path   =
        File.join(app.config.paths["public"].first, app.config.assets.prefix)

      app.assets = Propshaft::Assembly.new(app.config.assets)

      app.routes.prepend do
        mount app.assets.server => app.assets.config.prefix
      end

      ActiveSupport.on_load(:action_view) do
        include Propshaft::Helper
      end
    end

    rake_tasks do |app|
      namespace :assets do
        desc "Compile all the assets named in config.assets.precompile"
        task precompile: :environment do
          Rails.application.assets.processor.process
        end
      end
    end
  end
end
