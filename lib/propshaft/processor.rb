class Propshaft::Processor
  MANIFEST_FILENAME = ".manifest.json"

  attr_reader :load_path, :output_path

  def initialize(load_path:, output_path:)
    @load_path, @output_path = load_path, output_path
  end

  def process
    ensure_output_path_exists
    write_manifest
    copy_assets
    compress_assets
  end

  private
    def ensure_output_path_exists
      FileUtils.mkdir_p output_path
    end

    def write_manifest
      File.open(output_path.join(MANIFEST_FILENAME), "wb+") do |manifest|
        manifest.write load_path.manifest.to_json
      end
    end

    def copy_assets
      load_path.assets.each do |asset|
        FileUtils.mkdir_p output_path.join(asset.digested_path.parent)
        FileUtils.copy asset.path, output_path.join(asset.digested_path)
      end
    end

    def compress_assets
      # FIXME: Only try to compress text assets with brotli
      load_path.assets.each do |asset|
        compress_asset output_path.join(asset.digested_path)
      end if compressor_available?
    end

    def compress_asset(path)
      `brotli #{path} -o #{path}.br`
    end

    def compressor_available?
      `which brotli`.present?
    end
end
