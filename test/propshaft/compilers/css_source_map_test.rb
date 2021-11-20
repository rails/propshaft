require "test_helper"
require "minitest/mock"
require "propshaft/asset"
require "propshaft/assembly"
require "propshaft/compilers"

class Propshaft::Compilers::CssSourceMapTest < ActiveSupport::TestCase
  setup do
    @assembly = Propshaft::Assembly.new(ActiveSupport::OrderedOptions.new.tap { |config| 
      config.paths = [ Pathname.new("#{__dir__}/../../fixtures/assets/vendor") ]
      config.output_path = Pathname.new("#{__dir__}/../../fixtures/output")
      config.prefix = "/assets"
    })

    @assembly.compilers.register "text/css", Propshaft::Compilers::CssSourceMap
  end

  test "no sourcemap" do
    compiled = compile_asset_with_content(<<~EOF)
      .hero { background: url(file.jpg); }
    EOF
    assert_equal <<~EOF, compiled
      .hero { background: url(file.jpg); }
    EOF
  end

  test "missing source map" do
    compiled = compile_asset_with_content(<<~EOF)
      .hero { background: url(file.jpg); }
      /*# sourceMappingURL=missing.css.map */
    EOF
    assert_equal <<~EOF, compiled
      .hero { background: url(file.jpg); }

    EOF
  end

  test "present source map" do
    compiled = compile_asset_with_content(<<~EOF)
      .hero { background: url(file.jpg); }
      /*# sourceMappingURL=test.css.map */
    EOF
    assert_match %r[.hero { background: url\(file\.jpg\); }\n/\*# sourceMappingURL=test\.css-[a-z0-9]{40}\.map \*/], compiled
  end

  private
    def compile_asset_with_content(content)
      root_path    = Pathname.new("#{__dir__}/../../fixtures/assets/vendor")
      logical_path = "foobar/source/test.css"

      asset     = Propshaft::Asset.new(root_path.join(logical_path), logical_path: logical_path)
      asset.stub :content, content do
        @assembly.compilers.compile(asset)
      end
    end
end
