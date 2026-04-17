require "test_helper"
require "propshaft/assembly"
require "propshaft/server"

class Propshaft::ServerTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  class RackApp
    attr_reader :calls

    def initialize
      @calls = []
    end

    def call(env)
      @calls << env
      [200, {}, ["OK"]]
    end
  end

  setup do
    @assembly = Propshaft::Assembly.new(ActiveSupport::OrderedOptions.new.tap { |config|
      config.paths = [Pathname.new("#{__dir__}/../fixtures/assets/vendor"), Pathname.new("#{__dir__}/../fixtures/assets/first_path")]
      config.output_path = Pathname.new("#{__dir__}../fixtures/output")
      config.prefix = "/assets"
    })

    @rack_app = RackApp.new
    @assembly.compilers.register "text/css", Propshaft::Compiler::CssAssetUrls
    @server = Propshaft::Server.new(@rack_app, @assembly)
  end

  test "forward requests not under prefix" do
    get "/test"
    assert_not_empty @rack_app.calls
  end

  test "forward requests that aren't GET or HEAD" do
    asset = @assembly.load_path.find("foobar/source/test.css")
    post "/assets/#{asset.digested_path}"
    assert_not_empty @rack_app.calls
  end

  test "serve a compiled file" do
    asset = @assembly.load_path.find("foobar/source/test.css")
    get "/assets/#{asset.digested_path}"

    assert_equal 200, last_response.status
    assert_equal last_response.body.bytesize.to_s, last_response.headers['content-length']
    assert_equal "text/css; charset=utf-8", last_response.headers['content-type']
    assert_equal "Accept-Encoding", last_response.headers['vary']
    assert_equal "\"#{asset.digest}\"", last_response.headers['etag']
    assert_equal "public, max-age=31536000, immutable", last_response.headers['cache-control']
    assert_equal ".hero { background: url(\"/assets/foobar/source/file-3e6a1297.jpg\") }\n",
                 last_response.body
  end

  test "serve a predigested file" do
    asset = @assembly.load_path.find("file-already-abcdefVWXYZ0123456789_-.digested.css")
    get "/assets/#{asset.digested_path}"
    assert_equal 200, last_response.status
  end

  test "serve a sourcemap" do
    asset = @assembly.load_path.find("file-is-a-sourcemap.js.map")
    get "/assets/#{asset.digested_path}"
    assert_equal 200, last_response.status
  end

  test "serve an HTML file with charset" do
    asset = @assembly.load_path.find("test.html")
    get "/assets/#{asset.digested_path}"

    assert_equal 200, last_response.status
    assert_equal "text/html; charset=utf-8", last_response.headers['content-type']
  end

  test "serve a JS file without charset" do
    asset = @assembly.load_path.find("again.js")
    get "/assets/#{asset.digested_path}"

    assert_equal 200, last_response.status
    assert_equal "text/javascript", last_response.headers['content-type']
  end

  test "not found" do
    get "/assets/not-found.js"

    assert_equal 404, last_response.status
    assert_equal "9", last_response.headers['content-length']
    assert_equal "text/plain", last_response.headers['content-type']
    assert_equal "Not found", last_response.body
    assert_not last_response.headers.key?('cache-control')
    assert_not last_response.headers.key?('etag')
    assert_not last_response.headers.key?('accept-encoding')
  end

  test "not found if digest does not match" do
    asset = @assembly.load_path.find("foobar/source/test.css")
    get "/assets/#{asset.logical_path}"
    assert_equal 404, last_response.status
  end

  private
    def app
      @app ||= Rack::Lint.new(@server)
    end
end
