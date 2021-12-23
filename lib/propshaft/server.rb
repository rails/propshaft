require "rack/utils"

class Propshaft::Server
  def initialize(assembly)
    @assembly = assembly
  end

  def call(env)
    path, digest = extract_path_and_digest(env)

    if (asset = @assembly.load_path.find(path)) && asset.fresh?(digest)
      compiled_content = @assembly.compilers.compile(asset)

      [ 
        200, 
        {
          "Content-Length"  => compiled_content.length.to_s,
          "Content-Type"    => asset.content_type.to_s,
          "Accept-Encoding" => "Vary",
          "ETag"            => asset.digest,
          "Cache-Control"   => "public, max-age=31536000, immutable"
        },
        [ compiled_content ]
      ]
    else
      [ 404, { "Content-Type" => "text/plain", "Content-Length" => "9" }, [ "Not found" ] ]
    end
  end

  def inspect
    self.class.inspect
  end

  private
    def extract_path_and_digest(env)
      full_path = Rack::Utils.unescape(env["PATH_INFO"].to_s.sub(/^\//, ""))
      digest    = full_path[/-([0-9a-zA-Z]{7,128})\.(?!digested)[^.]+\z/, 1]
      path      = digest ? full_path.sub("-#{digest}", "") : full_path

      [ path, digest ]
    end
end
