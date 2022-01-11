require "rails"
require "active_support/ordered_options"

module Propshaft
  class Railtie < ::Rails::Railtie
    config.assets = ActiveSupport::OrderedOptions.new
    config.assets.paths       = []
    config.assets.prefix      = "/assets"
    config.assets.compilers   = [
      [ "text/css", Propshaft::Compilers::CssAssetUrls ],
      [ "text/css", Propshaft::Compilers::SourceMappingUrls ],
      [ "text/javascript", Propshaft::Compilers::SourceMappingUrls ]
    ]
    config.assets.sweep_cache = Rails.env.development?

    # Register propshaft initializer to copy the assets path in all the Rails Engines.
    # This makes possible for us to keep all `assets` config in this Railtie, but still
    # allow engines to automatically register their own paths.
    Rails::Engine.initializer "propshaft.append_assets_path", group: :all do |app|
      app.config.assets.paths.unshift(*paths["vendor/assets"].existent_directories)
      app.config.assets.paths.unshift(*paths["lib/assets"].existent_directories)
      app.config.assets.paths.unshift(*paths["app/assets"].existent_directories)
    end

    config.after_initialize do |app|
      config.assets.output_path ||=
        Pathname.new(File.join(app.config.paths["public"].first, app.config.assets.prefix))

      app.assets = Propshaft::Assembly.new(app.config.assets)

      if app.config.public_file_server.enabled
        app.routes.prepend do
          mount app.assets.server => app.assets.config.prefix
        end
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

    rake_tasks do
      load "propshaft/railties/assets.rake"
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
