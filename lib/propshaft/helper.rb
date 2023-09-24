module Propshaft
  module Helper
    def compute_asset_path(path, options = {})
      Rails.application.assets.resolver.resolve(path) || raise(MissingAssetError.new(path))
    end

    # Add an option to call `stylesheet_link_tag` with `:all` to include every css file found on the load path.
    def stylesheet_link_tag(*sources)
      if sources.first == :all
        super *all_stylesheets_paths
      else
        super
      end
    end

    # Returns a sorted and unique array of logical paths for all stylesheets in the load path.
    def all_stylesheets_paths
      Rails.application.assets.load_path
        .assets(content_types: [ Mime::EXTENSION_LOOKUP["css"] ])
        .collect { |css| css.logical_path.to_s }
        .sort
        .uniq
    end
  end
end
