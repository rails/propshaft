require "rack/utils"

class Propshaft::Server
  def initialize(load_path)
    @load_path = load_path
  end

  def call(env)
    if asset = @load_path.find(requested_path(env))
      [ 200, headers(asset, env), [ asset.content ] ]
    else
      [ 404, { "Content-Type" => "text/plain", "Content-Length" => "9" }, [ "Not found" ] ]
    end
  end

  private
    def requested_path(env)
      Rack::Utils.unescape(env["PATH_INFO"].to_s.sub(/^\//, ""))
    end

    def headers(asset, env)
      {
        "Content-Length" => asset.length.to_s,
        "Content-Type"   => asset.content_type,
        "ETag"           => asset.digest,
        "Cache-Control"  => "public, must-revalidate"
      }
    end
end
