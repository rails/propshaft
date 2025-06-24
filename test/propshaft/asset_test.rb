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

    assert_equal "file-is-a-sourcemap-da39a3ee.js.map",
      find_asset("file-is-a-sourcemap.js.map").digested_path.to_s
  end

  test "integrity" do
    assert_equal "sha256-+C/K/0dPvIdSC8rl/NDS8zqPp08R0VH+hKMM4D8tNJs=",
      find_asset("one.txt").integrity(hash_algorithm: "sha256").to_s

    assert_equal "sha384-LdS8l2QTAF8bD8WPb8QSQv0skTWHhmcnS2XU5LBkVQneGzqIqnDRskQtJvi7ADMe",
      find_asset("one.txt").integrity(hash_algorithm: "sha384").to_s

    assert_equal "sha512-wzPP7om24750PjHXRlgiDOhILPd4V2AbLRxomBudQaTDI1eYZkM5j8pSH/ylSSUxiGqXR3F6lgVCbsmXkqKrEg==",
      find_asset("one.txt").integrity(hash_algorithm: "sha512").to_s

    exception = assert_raises StandardError do
      find_asset("one.txt").integrity(hash_algorithm: "md5")
    end

    assert_equal "Subresource Integrity hash algorithm must be one of SHA2 family (sha256, sha384, sha512)", exception.message
  end

  test "value object equality" do
    assert_equal find_asset("one.txt"), find_asset("one.txt")
  end

  test "costly methods are memoized" do
    asset = find_asset("one.txt")
    assert_equal asset.digest.object_id, asset.digest.object_id
  end

  test "digest depends on first level of compiler dependency" do
    open_asset_with_reset("dependent/b.css") do |asset_file|
      digest_before_dependency_change = find_asset("dependent/a.css").digest

      asset_file.write "changes!"
      asset_file.flush

      digest_after_dependency_change = find_asset("dependent/a.css").digest

      assert_not_equal digest_before_dependency_change, digest_after_dependency_change
    end
  end

  test "digest depends on second level of compiler dependency" do
    open_asset_with_reset("dependent/c.css") do |asset_file|
      digest_before_dependency_change = find_asset("dependent/a.css").digest

      asset_file.write "changes!"
      asset_file.flush

      digest_after_dependency_change = find_asset("dependent/a.css").digest

      assert_not_equal digest_before_dependency_change, digest_after_dependency_change
    end
  end

  private
    def find_asset(logical_path)
      root_path = Pathname.new("#{__dir__}/../fixtures/assets/first_path")
      path = root_path.join(logical_path)

      assembly = Propshaft::Assembly.new(ActiveSupport::OrderedOptions.new.tap { |config|
        config.paths = [ root_path ]
        config.compilers = [[ "text/css", Propshaft::Compiler::CssAssetUrls ]]
      })

      Propshaft::Asset.new(path, logical_path: logical_path, load_path: assembly.load_path)
    end

    def open_asset_with_reset(logical_path)
      dependency_path = Pathname.new("#{__dir__}/../fixtures/assets/first_path/#{logical_path}")
      existing_dependency_content = File.read(dependency_path)

      File.open(dependency_path, "a") { |f| yield f }
    ensure
      File.write(dependency_path, existing_dependency_content)
    end
end
