require "test_helper"
require "propshaft/assembly"
require "propshaft/server"

class Propshaft::ServerTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  setup do
    @assembly = Propshaft::Assembly.new(ActiveSupport::OrderedOptions.new.tap { |config|
      config.paths = [Pathname.new("#{__dir__}/../fixtures/assets/vendor"), Pathname.new("#{__dir__}/../fixtures/assets/first_path")]
      config.output_path = Pathname.new("#{__dir__}../fixtures/output")
    })

    @assembly.compilers.register "text/css", Propshaft::Compilers::CssAssetUrls
    @server = Propshaft::Server.new(@assembly)
  end

  test "serve a compiled file" do
    asset = @assembly.load_path.find("foobar/source/test.css")
    get "/#{asset.digested_path}"

    assert_equal 200, last_response.status
    assert_equal "94", last_response.headers['Content-Length']
    assert_equal "text/css", last_response.headers['Content-Type']
    assert_equal "Vary", last_response.headers['Accept-Encoding']
    assert_equal asset.digest, last_response.headers['ETag']
    assert_equal "public, max-age=31536000, immutable", last_response.headers['Cache-Control']
    assert_equal ".hero { background: url(\"/foobar/source/file-3e6a129785ee3caf8eff23db339997e85334bfa9.jpg\") }\n",
                 last_response.body
  end

  test "serve a predigested file" do
    asset = @assembly.load_path.find("file-already.css")
    get "/#{asset.digested_path}"
    assert_equal 200, last_response.status
  end

  test "not found" do
    get "/not-found.js"

    assert_equal 404, last_response.status
    assert_equal "9", last_response.headers['Content-Length']
    assert_equal "text/plain", last_response.headers['Content-Type']
    assert_equal "Not found", last_response.body
    assert_not last_response.headers.key?('Cache-Control')
    assert_not last_response.headers.key?('ETag')
    assert_not last_response.headers.key?('Accept-Encoding')
  end

  test "not found if digest does not match" do
    asset = @assembly.load_path.find("foobar/source/test.css")
    get "/#{asset.logical_path}"
    assert_equal 404, last_response.status
  end

  private
    def default_app
      builder = Rack::Builder.new
      builder.run @server
    end

    def app
      @app ||= Rack::Lint.new(default_app)
    end
end
