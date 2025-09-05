require "rack/utils"
require "rack/version"

class Propshaft::Server
  def initialize(app, assembly)
    @app = app
    @assembly = assembly
  end

  def call(env)
    execute_cache_sweeper_if_updated

    path = env["PATH_INFO"]
    method = env["REQUEST_METHOD"]

    if (method == "GET" || method == "HEAD") && path.start_with?(@assembly.prefix)
      path, digest = extract_path_and_digest(path)

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
          method == "HEAD" ? [] : [ compiled_content ]
        ]
      else
        [ 404, { Rack::CONTENT_TYPE => "text/plain", Rack::CONTENT_LENGTH => "9" }, [ "Not found" ] ]
      end
    else
      @app.call(env)
    end
  end

  def inspect
    self.class.inspect
  end

  private
    def extract_path_and_digest(path)
      path = path.delete_prefix(@assembly.prefix)
      path = Rack::Utils.unescape(path)

      Propshaft::Asset.extract_path_and_digest(path)
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
