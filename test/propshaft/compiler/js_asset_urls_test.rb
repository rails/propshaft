require "test_helper"
require "minitest/mock"
require "propshaft/asset"
require "propshaft/assembly"
require "propshaft/compilers"

require "propshaft/compiler/js_asset_urls"

module Propshaft
  class Compiler
    class JsAssetUrlsTest < ActiveSupport::TestCase
      setup do
        @options = ActiveSupport::OrderedOptions.new.tap do |config|
          config.paths = [Pathname.new("#{__dir__}/../../fixtures/assets/vendor")]
          config.output_path = Pathname.new("#{__dir__}/../../fixtures/output")
          config.prefix = "/assets"
        end
      end

      test "the asset exists" do
        js_content = <<~JS
          export default class extends Controller {
            init() {
              this.img = RAILS_ASSET_URL("/foobar/source/file.svg");
            }
          }
        JS

        compiled = compile_asset_with_content(js_content)

        assert_match(%r{this\.img = "/assets/foobar/source/file-[a-z0-9]{8}.svg"\;}, compiled)
      end

      test "the asset does not exist" do
        js_content = <<~JS
          export default class extends Controller {
            init() {
              this.img = RAILS_ASSET_URL("missing.svg");
            }
          }
        JS

        compiled = compile_asset_with_content(js_content)

        assert_match(/this\.img = "missing.svg"\;/, compiled)
      end

      private

      def compile_asset_with_content(content)
        # This has one more set of .. than it would in the propshaft repo
        root_path    = Pathname.new("#{__dir__}/../../fixtures/assets/vendor")
        logical_path = "foobar/source/test.js"

        assembly = Propshaft::Assembly.new(@options)
        assembly.compilers.register("text/javascript", Propshaft::Compiler::JsAssetUrls)

        asset = Propshaft::Asset.new(root_path.join(logical_path), logical_path: logical_path, load_path: assembly.load_path)
        asset.stub(:content, content) do
          assembly.compilers.compile(asset)
        end
      end
    end
  end
end
