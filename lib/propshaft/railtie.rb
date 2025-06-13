require "rails"
require "active_support/ordered_options"
require "propshaft/quiet_assets"

module Propshaft
  class Railtie < ::Rails::Railtie
    config.assets = ActiveSupport::OrderedOptions.new
    config.assets.paths          = []
    config.assets.excluded_paths = []
    config.assets.version        = "1"
    config.assets.prefix         = "/assets"
    config.assets.quiet          = false
    config.assets.compilers      = [
      [ "text/css", Propshaft::Compiler::CssAssetUrls ],
      [ "text/css", Propshaft::Compiler::SourceMappingUrls ],
      [ "text/javascript", Propshaft::Compiler::JsAssetUrls ],
      [ "text/javascript", Propshaft::Compiler::SourceMappingUrls ],
    ]
    config.assets.sweep_cache = Rails.env.development?
    config.assets.server = Rails.env.development? || Rails.env.test?
    config.assets.relative_url_root = nil

    # Register propshaft initializer to copy the assets path in all the Rails Engines.
    # This makes possible for us to keep all `assets` config in this Railtie, but still
    # allow engines to automatically register their own paths.
    Rails::Engine.initializer "propshaft.append_assets_path", group: :all do |app|
      app.config.assets.paths.unshift(*paths["vendor/assets"].existent_directories)
      app.config.assets.paths.unshift(*paths["lib/assets"].existent_directories)
      app.config.assets.paths.unshift(*paths["app/assets"].existent_directories)

      app.config.assets.paths = app.config.assets.paths.without(Array(app.config.assets.excluded_paths).collect(&:to_s))
    end

    config.after_initialize do |app|
      # Prioritize assets from within the application over assets of the same path from engines/gems.
      config.assets.paths.sort_by!.with_index { |path, i| [path.to_s.start_with?(Rails.root.to_s) ? 0 : 1, i] }

      config.assets.file_watcher ||= app.config.file_watcher

      config.assets.relative_url_root ||= app.config.relative_url_root
      config.assets.output_path ||=
        Pathname.new(File.join(app.config.paths["public"].first, app.config.assets.prefix))
      config.assets.manifest_path ||= config.assets.output_path.join(".manifest.json")

      app.assets = Propshaft::Assembly.new(app.config.assets)

      if config.assets.server
        app.routes.prepend do
          mount app.assets.server, at: app.assets.config.prefix
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

    initializer :quiet_assets do |app|
      if app.config.assets.quiet
        app.middleware.insert_before ::Rails::Rack::Logger, Propshaft::QuietAssets
      end
    end

    rake_tasks do
      load "propshaft/railties/assets.rake"
    end

    # Compatibility shiming (need to provide log warnings when used)
    config.assets.precompile     = []
    config.assets.debug          = nil
    config.assets.compile        = nil
    config.assets.css_compressor = nil
    config.assets.js_compressor  = nil
  end
end
