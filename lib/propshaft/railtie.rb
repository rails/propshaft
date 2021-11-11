require "rails"
require "rails/railtie"
require "active_support/ordered_options"

# FIXME: There's gotta be a better way than this hack?
class Rails::Engine < Rails::Railtie
  initializer "propshaft.append_assets_path", group: :all do |app|
    app.config.assets.paths.unshift(*paths["vendor/assets"].existent_directories)
    app.config.assets.paths.unshift(*paths["lib/assets"].existent_directories)
    app.config.assets.paths.unshift(*paths["app/assets"].existent_directories)
  end
end

module Propshaft
  class Railtie < ::Rails::Railtie
    config.assets = ActiveSupport::OrderedOptions.new
    config.assets.paths       = []
    config.assets.prefix      = "/assets"
    config.assets.compilers   = [ [ "text/css", Propshaft::Compilers::CssAssetUrls ] ]
    config.assets.sweep_cache = Rails.env.development?

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

      if config.assets.sweep_cache
        ActiveSupport.on_load(:action_controller_base) do
          before_action { Rails.application.assets.load_path.cache_sweeper.execute_if_updated }
        end
      end
    end

    initializer "propshaft.logger" do
      Propshaft.logger = config.assets.logger || Rails.logger
    end

    rake_tasks do |app|
      namespace :assets do
        desc "Compile all the assets from config.assets.paths"
        task precompile: :environment do
          Rails.application.assets.processor.process
        end

        desc "Remove config.assets.output_path"
        task clean: :environment do
          Rails.application.assets.processor.clean
        end

        desc "Print all the assets available in config.assets.paths"
        task reveal: :environment do
          Rails.application.assets.reveal
        end
      end
    end

    # Compatibility shiming (need to provide log warnings when used)
    config.assets.precompile     = []
    config.assets.debug          = nil
    config.assets.quiet          = nil
    config.assets.compile        = nil
    config.assets.version        = nil
    config.assets.css_compressor = nil
    config.assets.js_compressor  = nil
  end
end
