class Propshaft::Compilers::CssAssetUrls
  attr_reader :assembly

  def initialize(assembly)
    @assembly = assembly
  end

  def compile(input)
    input.gsub(/asset-path\(["']([^"')]+)["']\)/) do |match|
      %[url("/#{assembly.config.prefix}/#{assembly.load_path.find($1).digested_path}")]
    end
  end
end
