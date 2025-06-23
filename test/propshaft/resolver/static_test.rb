require "test_helper"
require "minitest/mock"
require "propshaft/resolver/static"

class Propshaft::Resolver::StaticTest < ActiveSupport::TestCase
  setup do
    @resolver = Propshaft::Resolver::Static.new(
      manifest_path: Pathname.new("#{__dir__}/../../fixtures/output/.manifest.json"),
      prefix: "/assets"
    )
  end

  test "resolving present asset returns uri path" do
    assert_equal \
      "/assets/one-f2e1ec14.txt",
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

  test "integrity for asset returns nil for simple manifest" do
    assert_nil @resolver.integrity("one.txt")
  end

  test "integrity for missing asset returns nil" do
    assert_nil @resolver.integrity("nowhere.txt")
  end

  test "resolver requests json optimizer gems to keep parsed manifest keys as strings" do
    stub = Proc.new do |_, opts|
      assert_equal false, opts[:symbolize_names]
      {}
    end

    JSON.stub :parse, stub do
      @resolver.resolve("one.txt")
    end
  end

  class Propshaft::Resolver::StaticTest::WithExtensibleManifest < ActiveSupport::TestCase
    setup do
      @resolver = Propshaft::Resolver::Static.new(
        manifest_path: Pathname.new("#{__dir__}/../../fixtures/output/.extensible_manifest.json"),
        prefix: "/assets"
      )
    end

    test "resolving present asset returns uri path" do
      assert_equal \
        "/assets/one-f2e1ec14.txt",
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

    test "integrity for asset returns value from extensible manifest" do
      assert_equal "sha384-LdS8l2QTAF8bD8WPb8QSQv0skTWHhmcnS2XU5LBkVQneGzqIqnDRskQtJvi7ADMe", @resolver.integrity("one.txt")
    end

    test "integrity for missing asset returns nil" do
      assert_nil @resolver.integrity("nowhere.txt")
    end

    test "resolver requests json optimizer gems to keep parsed manifest keys as strings" do
      stub = Proc.new do |_, opts|
        assert_equal false, opts[:symbolize_names]
        {}
      end

      JSON.stub :parse, stub do
        @resolver.resolve("one.txt")
      end
    end
  end
end
