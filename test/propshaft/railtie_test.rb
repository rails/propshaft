# frozen_string_literal: true

require "test_helper"

class Propshaft::RailtieTest < ActiveSupport::TestCase
  test "app paths only include the application's app/assets directories" do
    app_paths = Rails.application.config.assets.app_paths

    assert_equal [
      Rails.root.join("app/assets/javascripts").to_s,
      Rails.root.join("app/assets/stylesheets").to_s
    ], app_paths.sort
  end

  test "app assets exclude assets from the load path outside of app/assets" do
    assert_equal [ "goodbye.css", "hello_world.css" ],
      Rails.application.assets.load_path.app_asset_paths_by_type("css")

    assert_includes Rails.application.assets.load_path.asset_paths_by_type("css"), "library.css"
  end
end
