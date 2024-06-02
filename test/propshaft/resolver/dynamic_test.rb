require "test_helper"
require "propshaft/resolver/dynamic"

class Propshaft::Resolver::DynamicTest < ActiveSupport::TestCase
  setup do
    @load_path = Propshaft::LoadPath.new Pathname.new("#{__dir__}/../../fixtures/assets/first_path"), compilers: Propshaft::Compilers.new(nil)
    @resolver  = Propshaft::Resolver::Dynamic.new(load_path: @load_path, prefix: "/assets")
  end

  test "resolving present asset returns uri path" do
    assert_equal "/assets/one-f2e1ec14.txt",
      @resolver.resolve("one.txt")
  end

  test "reading static asset" do
    assert_equal "ASCII-8BIT", @resolver.read("one.txt").encoding.to_s
    assert_equal "One from first path", @resolver.read("one.txt")
  end

  test "reading static asset with encoding option" do
    assert_equal "UTF-8", @resolver.read("one.txt", encoding: "UTF-8").encoding.to_s
    assert_equal "One from first path", @resolver.read("one.txt", encoding: "UTF-8")
  end

  test "resolving missing asset returns nil" do
    assert_nil @resolver.resolve("nowhere.txt")
  end
end
