require "test_helper"
require "propshaft/load_path"
require "propshaft/processor"

class Propshaft::ProcessorTest < ActiveSupport::TestCase
  setup do
    @assembly = Propshaft::Assembly.new(ActiveSupport::OrderedOptions.new.tap { |config|
      config.output_path = Pathname.new("#{__dir__}/../fixtures/output")
      config.prefix = "/assets"
      config.paths = [
        Pathname.new("#{__dir__}/../fixtures/assets/first_path"),
        Pathname.new("#{__dir__}/../fixtures/assets/second_path")
      ]
    })
  end

  test "manifest is written" do
    processed do |processor|
      assert_equal "one-f2e1ec14.txt",
         JSON.parse(processor.output_path.join(".manifest.json").read)["one.txt"]
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
    def processed
      Dir.mktmpdir do |output_path|
        output_path = Pathname.new(output_path)
        processor = Propshaft::Processor.new(
          load_path: @assembly.load_path, output_path: output_path,
          compilers: @assembly.compilers, manifest_path: output_path.join(".manifest.json")
        )

        processor.process

        yield processor
      end
    end
end
