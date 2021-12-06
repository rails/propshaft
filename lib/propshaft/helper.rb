module Propshaft
  module Helper
    def compute_asset_path(path, options = {})
      Rails.application.assets.resolver.resolve(path) || raise(MissingAssetError.new(path))
    end
  end
end
