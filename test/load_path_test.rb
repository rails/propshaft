require_relative "./test_helper"
require "propshaft/load_path"

class LoadPathTest < ActiveSupport::TestCase
  setup do
    @load_path = Propshaft::LoadPath.new [
      Pathname.new("#{__dir__}/assets/first_path"),
      Pathname.new("#{__dir__}/assets/second_path")
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
end
