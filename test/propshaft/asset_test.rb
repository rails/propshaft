require "test_helper"
require "propshaft/asset"
require "propshaft/load_path"

class Propshaft::AssetTest < ActiveSupport::TestCase
  test "content" do
    assert_equal "ASCII-8BIT", find_asset("one.txt").content.encoding.to_s
    assert_equal "One from first path", find_asset("one.txt").content
  end

  test "content with encoding" do
    assert_equal "UTF-8", find_asset("one.txt").content(encoding: "UTF-8").encoding.to_s
    assert_equal "One from first path", find_asset("one.txt").content(encoding: "UTF-8")
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
    assert_equal "f2e1ec14", find_asset("one.txt").digest
  end

  test "fresh" do
    assert find_asset("one.txt").fresh?("f2e1ec14")
    assert_not find_asset("one.txt").fresh?("e206c34f")

    assert find_asset("file-already-abcdefVWXYZ0123456789_-.digested.css").fresh?(nil)
  end

  test "digested path" do
    assert_equal "one-f2e1ec14.txt",
      find_asset("one.txt").digested_path.to_s

    assert_equal "file-already-abcdefVWXYZ0123456789_-.digested.css",
      find_asset("file-already-abcdefVWXYZ0123456789_-.digested.css").digested_path.to_s

    assert_equal "file-already-abcdefVWXYZ0123456789_-.digested.debug.css",
      find_asset("file-already-abcdefVWXYZ0123456789_-.digested.debug.css").digested_path.to_s

    assert_equal "file-not.digested-e206c34f.css",
      find_asset("file-not.digested.css").digested_path.to_s
  end

  test "value object equality" do
    assert_equal find_asset("one.txt"), find_asset("one.txt")
  end

  test "costly methods are memoized" do
    asset = find_asset("one.txt")
    assert_equal asset.digest.object_id, asset.digest.object_id
  end

  private
    def find_asset(logical_path)
      root_path = Pathname.new("#{__dir__}/../fixtures/assets/first_path")
      path = root_path.join(logical_path)
      Propshaft::Asset.new(path, logical_path: logical_path)
    end
end
