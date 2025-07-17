require "rack/utils"
require "rack/version"

class Propshaft::Server
  def initialize(assembly)
    @assembly = assembly
  end

  def call(env)
    execute_cache_sweeper_if_updated
    path, digest = extract_path_and_digest(env)

    if (asset = @assembly.load_path.find(path)) && asset.fresh?(digest)
      compiled_content = asset.compiled_content

      [
        200,
        {
          Rack::CONTENT_LENGTH  => compiled_content.length.to_s,
          Rack::CONTENT_TYPE    => asset.content_type.to_s,
          VARY                  => "Accept-Encoding",
          Rack::ETAG            => "\"#{asset.digest}\"",
          Rack::CACHE_CONTROL   => "public, max-age=31536000, immutable"
        },
        [ compiled_content ]
      ]
    else
      [ 404, { Rack::CONTENT_TYPE => "text/plain", Rack::CONTENT_LENGTH => "9" }, [ "Not found" ] ]
    end
  end

  def inspect
    self.class.inspect
  end

  private
    def extract_path_and_digest(env)
      full_path = Rack::Utils.unescape(env["PATH_INFO"].to_s.sub(/^\//, ""))

      Propshaft::Asset.extract_path_and_digest(full_path)
    end

    if Gem::Version.new(Rack::RELEASE) < Gem::Version.new("3")
      VARY = "Vary"
    else
      VARY = "vary"
    end

    def execute_cache_sweeper_if_updated
      if @assembly.config.sweep_cache
        @assembly.load_path.cache_sweeper.execute_if_updated
      end
    end
end
