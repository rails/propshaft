require "test_helper"
require "minitest/mock"
require "propshaft/asset"
require "propshaft/assembly"
require "propshaft/compilers"

class Propshaft::Compilers::JavascriptAssetUrlsTest < ActiveSupport::TestCase
  setup do
    @assembly = Propshaft::Assembly.new(ActiveSupport::OrderedOptions.new.tap { |config|
      config.paths = [ Pathname.new("#{__dir__}/../../fixtures/assets/vendor") ]
      config.output_path = Pathname.new("#{__dir__}/../../fixtures/output")
      config.prefix = "/assets"
    })

    @assembly.compilers.register "text/javascript", Propshaft::Compilers::JavascriptAssetUrls
  end

  test "single quotes" do
    compiled = compile_asset_with_content(%(from './chunk-SVLTBI7C.js'))
    assert_match(/from '\/assets\/foobar\/source\/chunk-SVLTBI7C-[a-z0-9]{40}.js'/, compiled)
  end

  test "double quotes" do
    compiled = compile_asset_with_content(%(from "./chunk-SVLTBI7C.js"))
    assert_match(/from "\/assets\/foobar\/source\/chunk-SVLTBI7C-[a-z0-9]{40}.js"/, compiled)
  end

  test "import without parenthesis" do
    compiled = compile_asset_with_content(%(import "./chunk-SVLTBI7C.js"))
    assert_match(/import "\/assets\/foobar\/source\/chunk-SVLTBI7C-[a-z0-9]{40}.js"/, compiled)
  end

  test "import with parenthesis" do
    compiled = compile_asset_with_content(%(import\("./chunk-SVLTBI7C.js"\)))
    assert_match(/import\("\/assets\/foobar\/source\/chunk-SVLTBI7C-[a-z0-9]{40}.js"\)/, compiled)
  end

  private
    def compile_asset_with_content(content)
      root_path    = Pathname.new("#{__dir__}/../../fixtures/assets/vendor")
      logical_path = "foobar/source/test.js"

      asset     = Propshaft::Asset.new(root_path.join(logical_path), logical_path: logical_path)
      asset.stub :content, content do
        @assembly.compilers.compile(asset)
      end
    end
end
