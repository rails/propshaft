require "test_helper"
require "propshaft/asset"

class Propshaft::AssetTest < ActiveSupport::TestCase
  test "content" do
    assert_equal "One from first path", find_asset("one.txt").content
  end

  test "content type" do
    assert_equal "text/plain", find_asset("one.txt").content_type.to_s
    assert_equal "text/javascript", find_asset("again.js").content_type.to_s
    assert_equal "text/css", find_asset("another.css").content_type.to_s
  end

  test "length" do
    assert_equal 19, find_asset("one.txt").length
  end

  test "digest" do
    assert_equal "f2e1ec14d6856e1958083094170ca6119c529a73", find_asset("one.txt").digest
  end

  test "digested path" do
    assert_equal "one-f2e1ec14d6856e1958083094170ca6119c529a73.txt",
      find_asset("one.txt").digested_path.to_s
  end

  test "value object equality" do
    assert_equal find_asset("one.txt"), find_asset("one.txt")
  end
end
