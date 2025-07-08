require "test_helper"
require "propshaft/manifest"

class Propshaft::ManifestTest < ActiveSupport::TestCase
  test "serializes to the extensible manifest format with integrity hash value" do
    manifest = create_manifest("sha384")
    parsed_manifest = JSON.parse(manifest.to_json)

    manifest_entry = parsed_manifest["one.txt"]
    assert_equal "one-f2e1ec14.txt", manifest_entry["digested_path"]
    assert_equal "sha384-LdS8l2QTAF8bD8WPb8QSQv0skTWHhmcnS2XU5LBkVQneGzqIqnDRskQtJvi7ADMe", manifest_entry["integrity"]

    manifest_entry = parsed_manifest["another.css"]
    assert_equal "another-c464b1ee.css", manifest_entry["digested_path"]
    assert_equal "sha384-jUiHGq2aPNACr4g68crM1I28TitXJKYhEgokcX6W5VYGwufEKQxfLpe4GakM84ex", manifest_entry["integrity"]
  end

  test "serializes to the extensible manifest format without integrity hash algorithm" do
    manifest = create_manifest
    parsed_manifest = JSON.parse(manifest.to_json)

    manifest_entry = parsed_manifest["one.txt"]
    assert_equal "one-f2e1ec14.txt", manifest_entry["digested_path"]
    assert_nil manifest_entry["integrity"]

    manifest_entry = parsed_manifest["another.css"]
    assert_equal "another-c464b1ee.css", manifest_entry["digested_path"]
    assert_nil manifest_entry["integrity"]
  end

  test "loads from new extensible manifest format" do
    manifest_path = Pathname.new("#{__dir__}/../fixtures/new_manifest_format/.manifest.json")
    manifest = Propshaft::Manifest.from_path(manifest_path)

    entry = manifest["one.txt"]
    assert_not_nil entry
    assert_equal "one.txt", entry.logical_path
    assert_equal "one-f2e1ec14.txt", entry.digested_path
    assert_equal "sha384-LdS8l2QTAF8bD8WPb8QSQv0skTWHhmcnS2XU5LBkVQneGzqIqnDRskQtJvi7ADMe", entry.integrity
  end

  test "loads from old simple manifest format" do
    manifest_path = Pathname.new("#{__dir__}/../fixtures/output/.manifest.json")
    manifest = Propshaft::Manifest.from_path(manifest_path)

    entry = manifest["one.txt"]
    assert_not_nil entry
    assert_equal "one.txt", entry.logical_path
    assert_equal "one-f2e1ec14.txt", entry.digested_path
    assert_nil entry.integrity
  end

  test "push method adds entry to manifest" do
    manifest = Propshaft::Manifest.new
    entry = Propshaft::Manifest::ManifestEntry.new(
      logical_path: "test.js",
      digested_path: "test-abc123.js",
      integrity: "sha384-test"
    )

    manifest.push(entry)
    retrieved_entry = manifest["test.js"]

    assert_equal entry, retrieved_entry
    assert_equal "test.js", retrieved_entry.logical_path
    assert_equal "test-abc123.js", retrieved_entry.digested_path
    assert_equal "sha384-test", retrieved_entry.integrity
  end

  test "<< alias works for push method" do
    manifest = Propshaft::Manifest.new
    entry = Propshaft::Manifest::ManifestEntry.new(
      logical_path: "test.css",
      digested_path: "test-def456.css",
      integrity: nil
    )

    manifest << entry
    retrieved_entry = manifest["test.css"]

    assert_equal entry, retrieved_entry
    assert_equal "test.css", retrieved_entry.logical_path
    assert_equal "test-def456.css", retrieved_entry.digested_path
    assert_nil retrieved_entry.integrity
  end

  test "[] accessor returns nil for missing entries" do
    manifest = Propshaft::Manifest.new
    assert_nil manifest["nonexistent.js"]
  end

  test "push_asset method creates entry from asset" do
    manifest = Propshaft::Manifest.new(integrity_hash_algorithm: "sha384")
    asset = find_asset("one.txt")

    manifest.push_asset(asset)
    entry = manifest["one.txt"]

    assert_not_nil entry
    assert_equal "one.txt", entry.logical_path
    assert_equal "one-f2e1ec14.txt", entry.digested_path
    assert_not_nil entry.integrity
    assert entry.integrity.start_with?("sha384-")
  end

  test "push_asset without integrity algorithm" do
    manifest = Propshaft::Manifest.new
    asset = find_asset("one.txt")

    manifest.push_asset(asset)
    entry = manifest["one.txt"]

    assert_not_nil entry
    assert_equal "one.txt", entry.logical_path
    assert_equal "one-f2e1ec14.txt", entry.digested_path
    assert_nil entry.integrity
  end

  private
    def create_manifest(integrity_hash_algorithm = nil)
      Propshaft::Manifest.new(integrity_hash_algorithm:).tap do |manifest|
        manifest.push_asset(find_asset("one.txt"))
        manifest.push_asset(find_asset("another.css"))
      end
    end

    def find_asset(logical_path)
      root_path = Pathname.new("#{__dir__}/../fixtures/assets/first_path")
      path = root_path.join(logical_path)

      assembly = Propshaft::Assembly.new(ActiveSupport::OrderedOptions.new.tap { |config|
        config.paths = [ root_path ]
        config.compilers = [[ "text/css", Propshaft::Compiler::CssAssetUrls ]]
      })

      Propshaft::Asset.new(path, logical_path: logical_path, load_path: assembly.load_path)
    end
end
