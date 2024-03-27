require "test_helper"
require "minitest/mock"
require "propshaft/asset"
require "propshaft/assembly"
require "propshaft/compilers"

class Propshaft::Compiler::JsImportUrlsTest < ActiveSupport::TestCase
  setup do
    @options = ActiveSupport::OrderedOptions.new.tap { |config|
      config.paths = [ Pathname.new("#{__dir__}/../../fixtures/assets/vendor") ]
      config.output_path = Pathname.new("#{__dir__}/../../fixtures/output")
      config.prefix = "/assets"
    }
  end

  test "basic relative imports and exports to file in same folder" do
    compiled = compile_asset_with_content(%(import "./file.js"))
    assert_match(/import "\/assets\/foobar\/source\/file-[a-z0-9]{8}.js"/, compiled)
    compiled = compile_asset_with_content(%(import * from "./file.js"))
    assert_match(/import \* from "\/assets\/foobar\/source\/file-[a-z0-9]{8}.js"/, compiled)
    compiled = compile_asset_with_content(%(export * from "./file.js"))
    assert_match(/export \* from "\/assets\/foobar\/source\/file-[a-z0-9]{8}.js"/, compiled)
  end

  test "basic relative imports and exports to file with single quotes" do
    compiled = compile_asset_with_content(%(import './file.js'))
    assert_match(/import '\/assets\/foobar\/source\/file-[a-z0-9]{8}.js'/, compiled)
    compiled = compile_asset_with_content(%(import * from './file.js'))
    assert_match(/import \* from '\/assets\/foobar\/source\/file-[a-z0-9]{8}.js'/, compiled)
    compiled = compile_asset_with_content(%(export * from './file.js'))
    assert_match(/export \* from '\/assets\/foobar\/source\/file-[a-z0-9]{8}.js'/, compiled)
  end

  test "multiline imports and exports to file in same folder" do
    compiled = compile_asset_with_content("import {\na as b\n} from \"./file.js\"")
    assert_match(/import {\na as b\n} from "\/assets\/foobar\/source\/file-[a-z0-9]{8}.js"/m, compiled)
    compiled = compile_asset_with_content("export {\na as b\n} from \"./file.js\"")
    assert_match(/export {\na as b\n} from "\/assets\/foobar\/source\/file-[a-z0-9]{8}.js"/m, compiled)
  end

  test "imports and exports with excess space to file in same folder" do
    compiled = compile_asset_with_content(%(import    "./file.js"))
    assert_match(/import    "\/assets\/foobar\/source\/file-[a-z0-9]{8}.js"/, compiled)
    compiled = compile_asset_with_content(%(import  *   from    "./file.js"))
    assert_match(/import  \*   from    "\/assets\/foobar\/source\/file-[a-z0-9]{8}.js"/, compiled)
    compiled = compile_asset_with_content(%(export    *  from     "./file.js"))
    assert_match(/export    \*  from     "\/assets\/foobar\/source\/file-[a-z0-9]{8}.js"/, compiled)
  end

  test "basic relative imports and exports to file in same parent" do
    compiled = compile_asset_with_content(%(import "../file.js"))
    assert_match(/import "\/assets\/foobar\/file-[a-z0-9]{8}.js"/, compiled)
    compiled = compile_asset_with_content(%(import * from "../file.js"))
    assert_match(/import \* from "\/assets\/foobar\/file-[a-z0-9]{8}.js"/, compiled)
    compiled = compile_asset_with_content(%(export * from "../file.js"))
    assert_match(/export \* from "\/assets\/foobar\/file-[a-z0-9]{8}.js"/, compiled)
  end

  test "multiline imports and exports to file in same parent" do
    compiled = compile_asset_with_content("import {\na as b\n} from \"../file.js\"")
    assert_match(/import {\na as b\n} from "\/assets\/foobar\/file-[a-z0-9]{8}.js"/m, compiled)
    compiled = compile_asset_with_content("export {\na as b\n} from \"../file.js\"")
    assert_match(/export {\na as b\n} from "\/assets\/foobar\/file-[a-z0-9]{8}.js"/m, compiled)
  end

  test "imports and exports with excess space to file in same parent" do
    compiled = compile_asset_with_content(%(import    "../file.js"))
    assert_match(/import    "\/assets\/foobar\/file-[a-z0-9]{8}.js"/, compiled)
    compiled = compile_asset_with_content(%(import  *   from    "../file.js"))
    assert_match(/import  \*   from    "\/assets\/foobar\/file-[a-z0-9]{8}.js"/, compiled)
    compiled = compile_asset_with_content(%(export    *  from     "../file.js"))
    assert_match(/export    \*  from     "\/assets\/foobar\/file-[a-z0-9]{8}.js"/, compiled)
  end

  test "basic relative imports and exports to file in the root" do
    compiled = compile_asset_with_content(%(import "/file.js"))
    assert_match(/import "\/assets\/file-[a-z0-9]{8}.js"/, compiled)
    compiled = compile_asset_with_content(%(import * from "/file.js"))
    assert_match(/import \* from "\/assets\/file-[a-z0-9]{8}.js"/, compiled)
    compiled = compile_asset_with_content(%(export * from "/file.js"))
    assert_match(/export \* from "\/assets\/file-[a-z0-9]{8}.js"/, compiled)
  end

  test "multiline imports and exports to file in the root" do
    compiled = compile_asset_with_content("import {\na as b\n} from \"/file.js\"")
    assert_match(/import {\na as b\n} from "\/assets\/file-[a-z0-9]{8}.js"/m, compiled)
    compiled = compile_asset_with_content("export {\na as b\n} from \"/file.js\"")
    assert_match(/export {\na as b\n} from "\/assets\/file-[a-z0-9]{8}.js"/m, compiled)
  end

  test "imports and exports with excess space to file in the root" do
    compiled = compile_asset_with_content(%(import    "/file.js"))
    assert_match(/import    "\/assets\/file-[a-z0-9]{8}.js"/, compiled)
    compiled = compile_asset_with_content(%(import  *   from    "/file.js"))
    assert_match(/import  \*   from    "\/assets\/file-[a-z0-9]{8}.js"/, compiled)
    compiled = compile_asset_with_content(%(export    *  from     "/file.js"))
    assert_match(/export    \*  from     "\/assets\/file-[a-z0-9]{8}.js"/, compiled)
  end

  test "basic relative dynamic imports to file in same folder" do
    compiled = compile_asset_with_content(%(import("./file.js").then()))
    assert_match(/import\("\/assets\/foobar\/source\/file-[a-z0-9]{8}.js"\).then\(\)/, compiled)
  end

  test "basic relative dynamic imports to file with single quotes" do
    compiled = compile_asset_with_content(%(import('./file.js')))
    assert_match(/import\('\/assets\/foobar\/source\/file-[a-z0-9]{8}.js'\)/, compiled)
  end

  test "dynamic imports with excess space to file in same folder" do
    compiled = compile_asset_with_content(%(import  \(  "./file.js"    \) ))
    assert_match(/import  \(  "\/assets\/foobar\/source\/file-[a-z0-9]{8}.js"    \)/, compiled)
  end

  test "missing asset" do
    compiled = compile_asset_with_content(%(import "./nothere.js"))
    assert_match(/import "\.\/nothere.js"/, compiled)
    compiled = compile_asset_with_content(%(import * from "./nothere.js"))
    assert_match(/import \* from "\.\/nothere.js"/, compiled)
    compiled = compile_asset_with_content(%(export * from "./nothere.js"))
    assert_match(/export \* from "\.\/nothere.js"/, compiled)
    compiled = compile_asset_with_content(%(import("./nothere.js").then()))
    assert_match(/import\("\.\/nothere.js"\).then\(\)/, compiled)
  end

  test "relative protocol url" do
    compiled = compile_asset_with_content(%(import "//rubyonrails.org/assets/main.js"))
    assert_match(/import "\/\/rubyonrails\.org\/assets\/main\.js"/, compiled)
  end

  private
    def compile_asset_with_content(content)
      root_path    = Pathname.new("#{__dir__}/../../fixtures/assets/vendor")
      logical_path = "foobar/source/test.js"

      asset     = Propshaft::Asset.new(root_path.join(logical_path), logical_path: logical_path)
      asset.stub :content, content do
        assembly = Propshaft::Assembly.new(@options)
        assembly.compilers.register "text/javascript", Propshaft::Compiler::JsImportUrls
        assembly.compilers.compile(asset)
      end
    end
end
