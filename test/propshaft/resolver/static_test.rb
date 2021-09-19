require "test_helper"
require "propshaft/resolver/static"

class Propshaft::Resolver::StaticTest < ActiveSupport::TestCase
  setup do
    @load_path = Propshaft::LoadPath.new Pathname.new("#{__dir__}/../../fixtures/assets/first_path")
    @resolver  = Propshaft::Resolver::Dynamic.new(load_path: @load_path, prefix: "/assets")
  end

  test "resolving present asset returns uri path" do
    assert_equal "/assets/one.txt", @resolver.resolve("one.txt")
  end

  test "resolving missing asset returns nil" do
    assert_nil @resolver.resolve("nowhere.txt")
  end
end
