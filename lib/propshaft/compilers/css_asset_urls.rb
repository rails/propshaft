# frozen_string_literal: true

class Propshaft::Compilers::CssAssetUrls
  attr_reader :assembly

  def initialize(assembly)
    @assembly = assembly
  end

  def compile(logical_path, input)
    input.gsub(/url\(\s*["']?(?!(?:\#|data|http))([^"'\s)]+)\s*["']?\)/.freeze) do
      resolved_path = resolve_path(logical_path.dirname, $1)
      resolved_path, mask = extract_svg_mask(resolved_path.to_s)
      %[url("#{assembly.config.prefix}/#{assembly.load_path.find(resolved_path).digested_path}#{mask}")]
    end
  end

  def resolve_path(directory, filename)
    if filename.start_with?("../")
      Pathname.new(directory + filename).relative_path_from("")
    elsif filename.start_with?("/")
      filename.delete_prefix("/")
    else
      directory + filename.delete_prefix("./")
    end
  end

  def extract_svg_mask(resolved_path)
    mask = resolved_path[/(\#.+)\z/.freeze, 1]
    path = mask ? resolved_path.sub(mask, "") : resolved_path

    [path, mask]
  end
end
