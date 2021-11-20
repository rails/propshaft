# frozen_string_literal: true
require "propshaft/errors"

class Propshaft::Compilers::CssSourceMap
  attr_reader :assembly

  SOURCE_MAPPING_URL_PATTERN = /\/\*# sourceMappingURL=(.*\.map) \*\//

  def initialize(assembly)
    @assembly = assembly
  end

  def compile(logical_path, input)
    input.gsub(SOURCE_MAPPING_URL_PATTERN) do
      source_map_path = $1
      logical_source_map_path = "#{logical_path.dirname}/#{source_map_path}"
      source_map_asset = assembly.load_path.find(logical_source_map_path)

      if not source_map_asset.nil?
        source_mapping_url = source_map_asset.digested_path.basename
        "/*# sourceMappingURL=#{source_mapping_url} */\n"
      else
        Propshaft.logger.warn "Removed sourceMappingURL comment for missing asset '#{logical_source_map_path}'"
        nil
      end
    end
  end
end
