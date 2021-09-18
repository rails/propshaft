module Propshaft::Helper
  def compute_asset_path(path, options = {})
    if (manifest_file = Rails.root.join("public/assets/.manifest.json")).exist?
      File.join \
        Rails.application.config.assets.prefix,
        JSON.parse(manifest_file.read)[path]
    else
      File.join \
        Rails.application.config.assets.prefix,
        Rails.application.assets.find(path).logical_path
    end
  end
end
