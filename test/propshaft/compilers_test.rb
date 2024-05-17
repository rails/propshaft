require "test_helper"
require "propshaft/asset"
require "propshaft/assembly"
require "propshaft/compilers"

class Propshaft::CompilersTest < ActiveSupport::TestCase
  setup do
    @assembly = Propshaft::Assembly.new(ActiveSupport::OrderedOptions.new.tap { |config|
      config.paths = [ Pathname.new("#{__dir__}/../fixtures/assets/first_path") ]
      config.output_path = Pathname.new("#{__dir__}/../fixtures/output")
      config.prefix = "/assets"
    })
  end

  test "replace asset-path function in css with digested url" do
    @assembly.compilers.register "text/css", Propshaft::Compiler::CssAssetUrls
    assert_match(/"\/assets\/archive-[a-z0-9]{8}.svg/, @assembly.compilers.compile(find_asset("another.css")))
  end

  private
    def find_asset(logical_path)
      root_path = Pathname.new("#{__dir__}/../fixtures/assets/first_path")
      load_path = Propshaft::LoadPath.new([ root_path ], compilers: Propshaft::Compilers.new(nil))
      Propshaft::Asset.new(root_path.join(logical_path), logical_path: logical_path, load_path: load_path)
    end
end
