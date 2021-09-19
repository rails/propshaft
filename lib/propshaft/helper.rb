module Propshaft::Helper
  def compute_asset_path(path, options = {})
    Rails.application.assets.resolver.resolve(path)
  end
end
