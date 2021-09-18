require "rack/utils"

class Propshaft::Server
  def initialize(load_path)
    @load_path = load_path
  end

  def call(env)
    if asset = @load_path.find(requested_asset(env))
      [ 200, headers(asset), [ asset.content ] ]
    else
      [ 404, { "Content-Type" => "text/plain", "Content-Length" => "9" }, [ "Not found" ] ]
    end
  end

  private
    def requested_asset(env)
      remove_digest(requested_path(env))
    end

    def requested_path(env)
      Rack::Utils.unescape(env["PATH_INFO"].to_s.sub(/^\//, ""))
    end

    def remove_digest(path)
      if digest = extract_digest(path)
        path.sub("-#{digest}", "")
      else
        path
      end
    end

    def extract_digest(path)
      path[/-([0-9a-f]{7,128})\.[^.]+\z/, 1]
    end

    def headers(asset)
      {
        "Content-Length" => asset.length.to_s,
        "Content-Type" => asset.content_type
      }
    end
end
