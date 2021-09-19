require "rails"
require "rails/railtie"
require "active_support/ordered_options"

module Propshaft
  class Railtie < ::Rails::Railtie
    config.assets = ActiveSupport::OrderedOptions.new
    config.assets.paths     = []
    config.assets.prefix    = "/assets"
    config.assets.compilers = [ [ "text/css", Propshaft::Compilers::CssAssetUrls ] ]

    # Compatibility shiming (need to provide log warnings when used)
    config.assets.precompile     = []
    config.assets.debug          = nil
    config.assets.quiet          = nil
    config.assets.compile        = nil
    config.assets.version        = nil
    config.assets.css_compressor = nil
    config.assets.js_compressor  = nil

    config.after_initialize do |app|
      config.assets.output_path ||=
        Pathname.new(File.join(app.config.paths["public"].first, app.config.assets.prefix))

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
        desc "Compile all the assets from config.assets.paths"
        task precompile: :environment do
          Rails.application.assets.processor.process
        end
      end
    end
  end
end
