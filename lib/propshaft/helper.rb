module Propshaft
  module Helper
    def compute_asset_path(path, options = {})
      Rails.application.assets.resolver.resolve(path) || raise(MissingAssetError.new(path))
    end

    # Add an option to call `stylesheet_link_tag` with
    # `:all` to include every css file found on the load path or
    # `:app` to include every css file found on `app/assets/stylesheets`.
    def stylesheet_link_tag(*sources, **options)
      case sources.first
      when :all
        super(*all_stylesheets_paths, **options)
      when :app
        super(*app_stylesheets_paths, **options)
      else
        super
      end
    end

    private
      def all_stylesheets_paths
        stylesheets_paths_for(Rails.application.assets.load_path)
      end

      def app_stylesheets_paths
        stylesheets_paths_for(
          Rails.application.assets.load_path.dup.tap do |load_path|
            load_path.paths = [ Rails.root.join("app/assets/stylesheets") ]
          end
        )
      end

      # Returns a sorted and unique array of logical paths for a stylesheets load path.
      def stylesheets_paths_for(load_path)
        load_path
          .assets(content_types: [ Mime::EXTENSION_LOOKUP["css"] ])
          .collect { |css| css.logical_path.to_s }
          .sort
          .uniq
      end
  end
end
