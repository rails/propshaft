require "test_helper"
require "propshaft/load_path"

class Propshaft::LoadPathTest < ActiveSupport::TestCase
  setup do
    @load_path = Propshaft::LoadPath.new [
      Pathname.new("#{__dir__}/../fixtures/assets/first_path"),
      Pathname.new("#{__dir__}/../fixtures/assets/second_path").to_s
    ], compilers: Propshaft::Compilers.new(nil)
  end

  test "find asset that only appears once in the paths" do
    assert_equal "Two from second path", @load_path.find("two.txt").content
  end

  test "find asset from first path if it appears twice in the paths" do
    assert_equal "One from first path", @load_path.find("one.txt").content
  end

  test "find nested asset" do
    assert_equal "Three from first path", @load_path.find("nested/three.txt").content
  end

  test "assets" do
    assert_includes @load_path.assets, find_asset("one.txt")
  end

  test "assets dont include dot files" do
    assert_not_includes @load_path.assets, find_asset(".stuff")
  end

  test "manifest" do
    @load_path.manifest.tap do |manifest|
      assert_equal "one-f2e1ec14.txt", manifest["one.txt"].digested_path.to_s
      assert_equal "nested/three-6c2b86a0.txt", manifest["nested/three.txt"].digested_path.to_s
    end
  end

  test "manifest with version" do
    @load_path = Propshaft::LoadPath.new(@load_path.paths, version: "1", compilers: Propshaft::Compilers.new(nil))
    @load_path.manifest.tap do |manifest|
      assert_equal "one-c9373b68.txt", manifest["one.txt"].digested_path.to_s
      assert_equal "nested/three-a41a5d38.txt", manifest["nested/three.txt"].digested_path.to_s
    end
  end

  test "missing load path directory" do
    assert_nil Propshaft::LoadPath.new(Pathname.new("#{__dir__}/../fixtures/assets/nowhere"), compilers: Propshaft::Compilers.new(nil)).find("missing")
  end

  test "deduplicate paths" do
    load_path = Propshaft::LoadPath.new [
      "app/javascript",
      "app/javascript/packs",
      "app/assets/stylesheets",
      "app/assets/images",
      "app/assets"
    ], compilers: Propshaft::Compilers.new(nil)

    paths = load_path.paths
    assert_equal 2, paths.count
    assert_equal Pathname.new("app/javascript"), paths.first
    assert_equal Pathname.new("app/assets"), paths.last
  end

  test "asset paths by type" do
    assert_equal \
      ["another.css", "dependent/a.css", "dependent/b.css", "dependent/c.css", "file-already-abcdefVWXYZ0123456789_-.digested.css", "file-already-abcdefVWXYZ0123456789_-.digested.debug.css", "file-not.digested.css"],
      @load_path.asset_paths_by_type("css")
  end

  test "asset paths by glob" do
    assert_equal \
      ["dependent/a.css", "dependent/b.css", "dependent/c.css"],
      @load_path.asset_paths_by_glob("**/dependent/*.css")
  end

  private
    def find_asset(logical_path)
      root_path = Pathname.new("#{__dir__}/../fixtures/assets/first_path")
      load_path = Propshaft::LoadPath.new([ root_path ], compilers: Propshaft::Compilers.new(nil))
      Propshaft::Asset.new(root_path.join(logical_path), logical_path: logical_path, load_path: load_path)
    end
end
