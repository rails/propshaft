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

  test "excluded paths are removed from the load path when the load path entry is a Pathname" do
    # Pathname load path entry, Pathname excluded path
    assert_not_includes Rails.application.config.assets.paths.map(&:to_s), Rails.root.join("app/javascript").to_s
    assert_not_includes Rails.application.assets.load_path.asset_paths_by_type("js"), "excluded.js"

    # Pathname load path entry, String excluded path
    assert_not_includes Rails.application.config.assets.paths.map(&:to_s), Rails.root.join("app/javascript_string").to_s
    assert_not_includes Rails.application.assets.load_path.asset_paths_by_type("js"), "excluded_by_string.js"
  end
end
