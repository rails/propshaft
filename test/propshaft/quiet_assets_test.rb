require "test_helper"
require "propshaft/quiet_assets"

class Propshaft::QuietAssetsTest < ActiveSupport::TestCase
  setup do
    Rails.logger.level = Logger::DEBUG
  end

  test "silences with default prefix" do
    assert_equal Logger::ERROR, middleware.call("PATH_INFO" => "/assets/stylesheets/application.css")
  end

  test "silences with custom prefix" do
    original = Rails.application.config.assets.prefix
    Rails.application.config.assets.prefix = "path/to"
    assert_equal Logger::ERROR, middleware.call("PATH_INFO" => "/path/to/thing")
  ensure
    Rails.application.config.assets.prefix = original
  end

  test "does not silence without match" do
    assert_equal Logger::DEBUG, middleware.call("PATH_INFO" => "/path/to/thing")
  end

  private

  def middleware
    @middleware ||= Propshaft::QuietAssets.new(->(env) { Rails.logger.level })
  end
end
