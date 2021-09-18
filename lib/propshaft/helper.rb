module Propshaft::Helper
  def compute_asset_path(path, options = {})
    File.join \
      Rails.application.config.assets.prefix,
      Rails.application.assets.find(path).logical_path
  end
end
