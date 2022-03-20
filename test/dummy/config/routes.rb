Rails.application.routes.draw do
  get 'sample/load_real_assets'
  get 'sample/load_nonexistent_assets'
  get 'sample/load_assets_with_integrity'
end
