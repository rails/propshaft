require "test_helper"
require "propshaft/resolver/dynamic"

class Propshaft::Resolver::DynamicTest < ActiveSupport::TestCase
  setup do
    @resolver = create_resolver
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

  test "integrity for asset returns value for configured hash format" do
    resolver = create_resolver(load_path_integrity_hash_algorithm: "sha384")
    assert_equal "sha384-LdS8l2QTAF8bD8WPb8QSQv0skTWHhmcnS2XU5LBkVQneGzqIqnDRskQtJvi7ADMe", resolver.integrity("one.txt")
  end

  test "integrity for asset returns nil for no configured hash format" do
    assert_nil @resolver.integrity("one.txt")
  end

  test "integrity for missing asset returns nil" do
    assert_nil @resolver.integrity("nowhere.txt")
  end

  private
    def create_resolver(load_path_integrity_hash_algorithm: nil)
      load_path = Propshaft::LoadPath.new(
        Pathname.new("#{__dir__}/../../fixtures/assets/first_path"),
        compilers: Propshaft::Compilers.new(nil),
        integrity_hash_algorithm: load_path_integrity_hash_algorithm
      )
      Propshaft::Resolver::Dynamic.new(load_path: load_path, prefix: "/assets")
    end
end
