require "test_helper"
require "minitest/mock"
require "propshaft/asset"
require "propshaft/assembly"
require "propshaft/compilers"

class Propshaft::Compilers::SourceMappingUrlsTest < ActiveSupport::TestCase
  setup do
    @options = ActiveSupport::OrderedOptions.new.tap { |config|
      config.paths = [ Pathname.new("#{__dir__}/../../fixtures/assets/mapped") ]
      config.output_path = Pathname.new("#{__dir__}/../../fixtures/output")
      config.prefix = "/assets"
    }
  end

  test "matching source map" do
    assert_match %r{//# sourceMappingURL=/assets/source.js-[a-z0-9]{40}\.map},
                  compile_asset(find_asset("source.js", fixture_path: "mapped"))
    assert_match %r{/\*# sourceMappingURL=/assets/source.css-[a-z0-9]{40}\.map},
                  compile_asset(find_asset("source.css", fixture_path: "mapped"))
  end

  test "matching nested source map" do
    assert_match %r{//# sourceMappingURL=/assets/nested/another-source.js-[a-z0-9]{40}\.map},
                  compile_asset(find_asset("nested/another-source.js", fixture_path: "mapped"))
  end

  test "missing source map" do
    assert_no_match %r{sourceMappingURL},
                     compile_asset(find_asset("sourceless.js", fixture_path: "mapped"))
    assert_no_match %r{sourceMappingURL},
                     compile_asset(find_asset("sourceless.css", fixture_path: "mapped"))
  end

  test "sourceMappingURL outside of a comment should be left alone" do
    assert_match %r{sourceMappingURL=sourceMappingURL-outside-comment.css.map},
                 compile_asset(find_asset("sourceMappingURL-outside-comment.css", fixture_path: "mapped"))
  end

  test "sourceMappingURL not at the beginning of the line should be left alone" do
    assert_match %r{sourceMappingURL=sourceMappingURL-not-at-start.css.map},
                  compile_asset(find_asset("sourceMappingURL-not-at-start.css", fixture_path: "mapped"))
  end

  test "host" do
    @options.host = "https://example.com"

    assert_match %r{//# sourceMappingURL=https://example.com/assets/source.js-[a-z0-9]{40}\.map},
                  compile_asset(find_asset("source.js", fixture_path: "mapped"))
  end

  test "relative url root" do
    @options.relative_url_root = "url-root"

    assert_match %r{//# sourceMappingURL=/url-root/assets/source.js-[a-z0-9]{40}\.map},
                  compile_asset(find_asset("source.js", fixture_path: "mapped"))
  end

  private
    def compile_asset(asset)

      assembly = Propshaft::Assembly.new(@options)
      assembly.compilers.register "text/javascript", Propshaft::Compilers::SourceMappingUrls
      assembly.compilers.register "text/css", Propshaft::Compilers::SourceMappingUrls

      assembly.compilers.compile(asset)
    end
end
