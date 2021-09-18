class Propshaft::Processor
  attr_reader :load_path, :output_path

  def initialize(load_path:, output_path:)
    @load_path, @output_path = load_path, output_path
  end

  def process
    FileUtils.mkdir_p output_path

    load_path.assets.values.each do |asset|
      FileUtils.cp asset.path, File.join(output_path, asset.digested_path)
    end
  end
end
