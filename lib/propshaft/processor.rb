class Propshaft::Processor
  attr_reader :load_path, :output_path, :manifest_filename

  def initialize(load_path:, output_path:, manifest_filename: ".manifest.json")
    @load_path, @output_path = load_path, output_path
    @manifest_filename = manifest_filename
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
      File.open(output_path.join(manifest_filename), "wb+") do |manifest|
        manifest.write load_path.manifest.to_json
      end
    end

    def copy_assets
      load_path.assets.each do |asset|
        FileUtils.mkdir_p File.join(output_path, asset.digested_path.parent)
        FileUtils.copy asset.path, File.join(output_path, asset.digested_path)
      end
    end

    def compress_assets
      # FIXME: Only try to compress text assets with brotli
      load_path.assets.each do |asset|
        compress_asset File.join(output_path, asset.digested_path)
      end if compressor_available?
    end

    def compress_asset(path)
      `brotli #{path} -o #{path}.br`
    end

    def compressor_available?
      `which brotli`.present?
    end
end
