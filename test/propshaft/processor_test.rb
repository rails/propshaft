require "test_helper"
require "propshaft/load_path"
require "propshaft/processor"

class Propshaft::ProcessorTest < ActiveSupport::TestCase
  setup do
    @assembly = create_assembly
  end

  test "manifest is written" do
    processed do |processor|
      manifest = JSON.load_file(processor.output_path.join(".manifest.json"))
      manifest_entry = manifest["one.txt"]

      assert_equal "one-f2e1ec14.txt", manifest_entry["digested_path"]
      assert_nil manifest_entry["integrity"], "Integrity should not be present by default"
    end
  end

  test "integrity is written in the manifest when configured" do
    assembly = create_assembly do |config|
      config.integrity_hash_algorithm = "sha384"
    end

    processed(assembly) do |processor|
      manifest = JSON.load_file(processor.output_path.join(".manifest.json"))
      manifest_entry = manifest["one.txt"]

      assert_equal manifest_entry["digested_path"], "one-f2e1ec14.txt"
      assert_equal manifest_entry["integrity"], "sha384-LdS8l2QTAF8bD8WPb8QSQv0skTWHhmcnS2XU5LBkVQneGzqIqnDRskQtJvi7ADMe"
    end
  end

  test "assets are copied" do
    processed do |processor|
      digested_asset_name = "one-f2e1ec14.txt"
      assert processor.output_path.join(digested_asset_name).exist?

      nested_digested_asset_name = "nested/three-6c2b86a0.txt"
      assert processor.output_path.join(nested_digested_asset_name).exist?
    end
  end

  test "assets are clobbered" do
    processed do |processor|
      processor.clobber
      assert_not File.exist?(processor.output_path)
      FileUtils.mkdir_p processor.output_path
    end
  end

  private
    def create_assembly
      Propshaft::Assembly.new(ActiveSupport::OrderedOptions.new.tap { |config|
        config.output_path = Pathname.new("#{__dir__}/../fixtures/output")
        config.prefix = "/assets"
        config.paths = [
          Pathname.new("#{__dir__}/../fixtures/assets/first_path"),
          Pathname.new("#{__dir__}/../fixtures/assets/second_path")
        ]
        yield config if block_given?
      })
    end

    def processed(assembly = @assembly)
      Dir.mktmpdir do |output_path|
        output_path = Pathname.new(output_path)
        processor = Propshaft::Processor.new(
          load_path: assembly.load_path, output_path: output_path,
          compilers: assembly.compilers, manifest_path: output_path.join(".manifest.json")
        )

        processor.process

        yield processor
      end
    end
end
