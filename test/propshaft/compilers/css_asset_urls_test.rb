require "test_helper"
require "minitest/mock"
require "propshaft/asset"
require "propshaft/assembly"
require "propshaft/compilers"

class Propshaft::Compilers::CssAssetUrlsTest < ActiveSupport::TestCase
  setup do
    @options = ActiveSupport::OrderedOptions.new.tap { |config|
      config.paths = [ Pathname.new("#{__dir__}/../../fixtures/assets/vendor") ]
      config.output_path = Pathname.new("#{__dir__}/../../fixtures/output")
      config.prefix = "/assets"
    }
  end

  test "basic" do
    compiled = compile_asset_with_content(%({ background: url(file.jpg); }))
    assert_match(/{ background: url\("\/assets\/foobar\/source\/file-[a-z0-9]{40}.jpg"\); }/, compiled)
  end

  test "blank spaces around name" do
    compiled = compile_asset_with_content(%({ background: url( file.jpg ); }))
    assert_match(/{ background: url\("\/assets\/foobar\/source\/file-[a-z0-9]{40}.jpg"\); }/, compiled)
  end

  test "quotes around name" do
    compiled = compile_asset_with_content(%({ background: url("file.jpg"); }))
    assert_match(/{ background: url\("\/assets\/foobar\/source\/file-[a-z0-9]{40}.jpg"\); }/, compiled)
  end

  test "single quotes around name" do
    compiled = compile_asset_with_content(%({ background: url('file.jpg'); }))
    assert_match(/{ background: url\("\/assets\/foobar\/source\/file-[a-z0-9]{40}.jpg"\); }/, compiled)
  end

  test "root directory" do
    compiled = compile_asset_with_content(%({ background: url('/file.jpg'); }))
    assert_match(/{ background: url\("\/assets\/file-[a-z0-9]{40}.jpg"\); }/, compiled)
  end

  test "same directory" do
    compiled = compile_asset_with_content(%({ background: url('./file.jpg'); }))
    assert_match(/{ background: url\("\/assets\/foobar\/source\/file-[a-z0-9]{40}.jpg"\); }/, compiled)
  end

  test "subdirectory" do
    compiled = compile_asset_with_content(%({ background: url('./images/file.jpg'); }))
    assert_match(/{ background: url\("\/assets\/foobar\/source\/images\/file-[a-z0-9]{40}.jpg"\); }/, compiled)
  end

  test "parent directory" do
    compiled = compile_asset_with_content(%({ background: url('../file.jpg'); }))
    assert_match(/{ background: url\("\/assets\/foobar\/file-[a-z0-9]{40}.jpg"\); }/, compiled)
  end

  test "grandparent directory" do
    compiled = compile_asset_with_content(%({ background: url('../../file.jpg'); }))
    assert_match(/{ background: url\("\/assets\/file-[a-z0-9]{40}.jpg"\); }/, compiled)
  end

  test "sibling directory" do
    compiled = compile_asset_with_content(%({ background: url('../sibling/file.jpg'); }))
    assert_match(/{ background: url\("\/assets\/foobar\/sibling\/file-[a-z0-9]{40}.jpg"\); }/, compiled)
  end

  test "mixed" do
    compiled = compile_asset_with_content(%({ mask-image: image(url(file.jpg), skyblue, linear-gradient(rgba(0, 0, 0, 1.0), transparent)); }))
    assert_match(/{ mask-image: image\(url\("\/assets\/foobar\/source\/file-[a-z0-9]{40}.jpg"\), skyblue, linear-gradient\(rgba\(0, 0, 0, 1.0\), transparent\)\); }/, compiled)
  end

  test "multiple" do
    compiled = compile_asset_with_content(%({ content: url(file.svg) url(file.svg); }))
    assert_match(/{ content: url\("\/assets\/foobar\/source\/file-[a-z0-9]{40}.svg"\) url\("\/assets\/foobar\/source\/file-[a-z0-9]{40}.svg"\); }/, compiled)
  end

  test "url" do
    compiled = compile_asset_with_content(%({ background: url('https://rubyonrails.org/images/rails-logo.svg'); }))
    assert_match "{ background: url('https://rubyonrails.org/images/rails-logo.svg'); }", compiled
  end

  test "relative protocol url" do
    compiled = compile_asset_with_content(%({ background: url('//rubyonrails.org/images/rails-logo.svg'); }))
    assert_match "{ background: url('//rubyonrails.org/images/rails-logo.svg'); }", compiled
  end

  test "data" do
    compiled = compile_asset_with_content(%({ background: url(data:image/png;base64,iRxVB0); }))
    assert_match "{ background: url(data:image/png;base64,iRxVB0); }", compiled
  end

  test "anchor" do
    compiled = compile_asset_with_content(%({ background: url(#IDofSVGpath); }))
    assert_match "{ background: url(#IDofSVGpath); }", compiled
  end

  test "fingerprint" do
    compiled = compile_asset_with_content(%({ background: url('/file.jpg?30af91bf14e37666a085fb8a161ff36d'); }))
    assert_match(/{ background: url\("\/assets\/file-[a-z0-9]{40}.jpg\?30af91bf14e37666a085fb8a161ff36d"\); }/, compiled)
  end

  test "svg anchor" do
    compiled = compile_asset_with_content(%({ content: url(file.svg#rails); }))
    assert_match(/{ content: url\("\/assets\/foobar\/source\/file-[a-z0-9]{40}.svg#rails"\); }/, compiled)
  end

  test "svg mask encoded anchor" do
    compiled = compile_asset_with_content(%({ background: url("data:image/svg+xml;charset=utf-8,%3Csvg mask='url(%23MyMask)'%3E%3C/svg%3E"); }))
    assert_match "{ background: url(\"data:image/svg+xml;charset=utf-8,%3Csvg mask='url(%23MyMask)'%3E%3C/svg%3E\"); }", compiled
  end

  test "non greedy anchors" do
    compiled = compile_asset_with_content(%({ content: url(file.svg#demo) url(file.svg#demo); }))
    assert_match(/{ content: url\("\/assets\/foobar\/source\/file-[a-z0-9]{40}.svg#demo"\) url\("\/assets\/foobar\/source\/file-[a-z0-9]{40}.svg#demo"\); }/, compiled)
  end

  test "missing asset" do
    compiled = compile_asset_with_content(%({ background: url("file-not-found.jpg"); }))
    assert_match(/{ background: url\("file-not-found.jpg"\); }/, compiled)
  end

  test "host" do
    @options.host = "https://example.com"

    compiled = compile_asset_with_content(%({ background: url(file.jpg); }))
    assert_match(/{ background: url\("https:\/\/example.com\/assets\/foobar\/source\/file-[a-z0-9]{40}.jpg"\); }/, compiled)
  end

  test "relative url root" do
    @options.relative_url_root = "url-root"

    compiled = compile_asset_with_content(%({ background: url(file.jpg); }))
    assert_match(/{ background: url\("\/url-root\/assets\/foobar\/source\/file-[a-z0-9]{40}.jpg"\); }/, compiled)
  end

  private
    def compile_asset_with_content(content)
      root_path    = Pathname.new("#{__dir__}/../../fixtures/assets/vendor")
      logical_path = "foobar/source/test.css"

      asset     = Propshaft::Asset.new(root_path.join(logical_path), logical_path: logical_path)
      asset.stub :content, content do
        assembly = Propshaft::Assembly.new(@options)
        assembly.compilers.register "text/css", Propshaft::Compilers::CssAssetUrls
        assembly.compilers.compile(asset)
      end
    end
end
