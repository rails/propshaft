require "propshaft/output_path"

class Propshaft::Processor
  MANIFEST_FILENAME = ".manifest.json"

  attr_reader :load_path, :output_path, :compilers

  def initialize(load_path:, output_path:, compilers:)
    @load_path, @output_path = load_path, output_path
    @compilers = compilers
  end

  def process
    ensure_output_path_exists
    write_manifest
    output_assets
  end

  def clobber
    FileUtils.rm_r(output_path) if File.exist?(output_path)
  end

  def clean
    Propshaft::OutputPath.new(output_path, load_path.manifest).clean(2, 1.hour)
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


    def output_assets
      load_path.assets.each do |asset|
        unless output_path.join(asset.digested_path).exist?
          Propshaft.logger.info "Writing #{asset.digested_path}"
          FileUtils.mkdir_p output_path.join(asset.digested_path.parent)
          output_asset(asset)
        end
      end
    end

    def output_asset(asset)
      compile_asset(asset) || copy_asset(asset)
    end

    def compile_asset(asset)
      File.open(output_path.join(asset.digested_path), "w+") do |file|
        begin
          file.write compilers.compile(asset)
        rescue Encoding::UndefinedConversionError
          # FIXME: Not sure if there's a better way here?
          file.write compilers.compile(asset).force_encoding("UTF-8")
        end
      end if compilers.compilable?(asset)
    end

    def copy_asset(asset)
      FileUtils.copy asset.path, output_path.join(asset.digested_path)
    end
end
