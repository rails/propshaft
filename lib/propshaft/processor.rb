class Propshaft::Processor
  attr_reader :load_path, :output_path

  def initialize(load_path:, output_path:)
    @load_path, @output_path = load_path, output_path
  end

  def process
    ensure_output_path_exists
    write_manifest
    copy_assets
  end

  private
    def ensure_output_path_exists
      FileUtils.mkdir_p output_path
    end

    def write_manifest
      File.open(File.join(output_path, ".manifest.json"), "wb+") do |manifest|
        manifest.write load_path.manifest.to_json
      end
    end

    def copy_assets
      load_path.assets.each do |asset|
        FileUtils.cp asset.path, File.join(output_path, asset.digested_path)
      end
    end
end
