module Propshaft
  module Helper
    def compute_asset_path(path, options = {})
      Rails.application.assets.resolver.resolve(path) || raise(MissingAssetError.new(path))
    end

    # Add an option to call `stylesheet_link_tag` with `:all` to include every css file found on the load path
    # or `:app` to include css files found in `Rails.root("app/assets/**/*.css")`, which will exclude lib/ and plugins.
    def stylesheet_link_tag(*sources, **options)
      case sources.first
      when :all
        super(*all_stylesheets_paths , **options)
      when :app
        super(*app_stylesheets_paths , **options)
      else
        super
      end
    end

    # Returns a sorted and unique array of logical paths for all stylesheets in the load path.
    def all_stylesheets_paths
      Rails.application.assets.load_path.asset_paths_by_type("css")
    end

    # Returns a sorted and unique array of logical paths for all stylesheets in app/assets/**/*.css.
    def app_stylesheets_paths
      Rails.application.assets.load_path.asset_paths_by_glob("#{Rails.root.join("app/assets")}/**/*.css")
    end
  end
end
