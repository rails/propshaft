require "rack/utils"

class Propshaft::Server
  def initialize(assembly)
    @assembly = assembly
  end

  def call(env)
    if asset = @assembly.load_path.find(requested_path(env))
      compiled_content = @assembly.compilers.compile(asset)

      [ 
        200, 
        {
          "Content-Length" => compiled_content.length.to_s,
          "Content-Type"   => asset.content_type,
          "ETag"           => asset.digest,
          "Cache-Control"  => "public, must-revalidate"
        },
        [ compiled_content ]
      ]
    else
      [ 404, { "Content-Type" => "text/plain", "Content-Length" => "9" }, [ "Not found" ] ]
    end
  end

  private
    def requested_path(env)
      Rack::Utils.unescape(env["PATH_INFO"].to_s.sub(/^\//, ""))
    end
end
