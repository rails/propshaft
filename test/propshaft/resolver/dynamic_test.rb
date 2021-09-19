require "test_helper"
require "propshaft/resolver/dynamic"

class Propshaft::Resolver::DynamicTest < ActiveSupport::TestCase
  setup do
    @load_path = Propshaft::LoadPath.new [
      Pathname.new("#{__dir__}/../../assets/first_path"),
      Pathname.new("#{__dir__}/../../assets/second_path")
    ]

    @resolver = Propshaft::Resolver::Dynamic.new(load_path: @load_path, prefix: "/assets")
  end

  test "resolving present asset returns uri path" do
    assert_equal "/assets/one.txt", @resolver.resolve("one.txt")
  end

  test "resolving missing asset returns nil" do
    assert_nil @resolver.resolve("nowhere.txt")
  end
end
