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
    assert_equal "sha384-RZLbo+FZ8rnE9ct6dNqDcgIYo7DBk/GaB4nCMnNsj6HWp0ePV8q8qky9Qemdpuwl", manifest_entry["integrity"]
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
