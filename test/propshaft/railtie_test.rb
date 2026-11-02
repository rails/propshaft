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

  test "gems installed inside the application are not app paths" do
    bundle_path = Rails.root.join("vendor/bundle/ruby/3.4.0")

    Bundler.stub(:bundle_path, bundle_path) do
      assert Propshaft::Railtie.app_path?(Rails.root.join("vendor/javascript"))
      assert_not Propshaft::Railtie.app_path?(bundle_path.join("gems/actiontext-8.1.0/app/assets/javascripts"))
    end
  end
end
