require "test_helper"
require "minitest/mock"
require "propshaft/asset"
require "propshaft/assembly"
require "propshaft/compilers"

class Propshaft::Compilers::SourceMappingUrlsTest < ActiveSupport::TestCase
  setup do
    @assembly = Propshaft::Assembly.new(ActiveSupport::OrderedOptions.new.tap { |config| 
      config.paths = [ Pathname.new("#{__dir__}/../../fixtures/assets/mapped") ]
      config.output_path = Pathname.new("#{__dir__}/../../fixtures/output")
      config.prefix = "/assets"
    })

    @assembly.compilers.register "text/javascript", Propshaft::Compilers::SourceMappingUrls
    @assembly.compilers.register "text/css", Propshaft::Compilers::SourceMappingUrls
  end

  test "matching source map" do
    assert_match /\/\/# sourceMappingURL=\/assets\/source.js-[a-z0-9]{40}\.map/, @assembly.compilers.compile(find_asset("source.js", fixture_path: "mapped"))
    assert_match /\/*# sourceMappingURL=\/assets\/source.css-[a-z0-9]{40}\.map/, @assembly.compilers.compile(find_asset("source.css", fixture_path: "mapped"))
  end

  test "matching nested source map" do
    assert_match /\/\/# sourceMappingURL=\/assets\/nested\/another-source.js-[a-z0-9]{40}\.map/, @assembly.compilers.compile(find_asset("nested/another-source.js", fixture_path: "mapped"))
  end

  test "missing source map" do
    assert_no_match /sourceMappingURL/, @assembly.compilers.compile(find_asset("sourceless.js", fixture_path: "mapped"))
    assert_no_match /sourceMappingURL/, @assembly.compilers.compile(find_asset("sourceless.css", fixture_path: "mapped"))
  end

  test "sourceMappingURL outside of a comment should be left alone" do
    assert_match /sourceMappingURL=sourceMappingURL-outside-comment.css.map/, @assembly.compilers.compile(find_asset("sourceMappingURL-outside-comment.css", fixture_path: "mapped"))
  end
end
