require "test_helper"
require "propshaft/load_path"

class Propshaft::LoadPathTest < ActiveSupport::TestCase
  setup do
    @load_path = Propshaft::LoadPath.new [
      Pathname.new("#{__dir__}/../fixtures/assets/first_path"),
      Pathname.new("#{__dir__}/../fixtures/assets/second_path")
    ]
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

  test "find asset from digested filename" do
    assert_equal "One from first path", @load_path.find("one-f2e1ec14d6856e1958083094170ca6119c529a73.txt").content
  end

  test "assets" do
    asset = Propshaft::Asset.new(
      Pathname.new("#{__dir__}/../fixtures/assets/first_path/one.text"),
      logical_path: Pathname.new("one.txt")
    )

    assert_includes @load_path.assets, asset
  end

  test "manifest" do
    @load_path.manifest.tap do |manifest|
      assert_equal "one-f2e1ec14d6856e1958083094170ca6119c529a73.txt", manifest["one.txt"]
      assert_equal "nested/three-6c2b86a0206381310375abdd9980863c2ea7b2c3.txt", manifest["nested/three.txt"]
    end
  end
end
