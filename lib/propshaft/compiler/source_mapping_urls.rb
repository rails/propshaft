# frozen_string_literal: true

require "propshaft/compiler"

class Propshaft::Compiler::SourceMappingUrls < Propshaft::Compiler
  SOURCE_MAPPING_PATTERN = %r{(//|/\*)# sourceMappingURL=(.+\.map)(\s*?\*\/)?\s*?\Z}

  def compile(logical_path, input)
    input.gsub(SOURCE_MAPPING_PATTERN) { source_mapping_url(asset_path($2, logical_path), $1, $3) }
  end

  private
    def asset_path(source_mapping_url, logical_path)
      if logical_path.dirname.to_s == "."
        source_mapping_url
      else
        logical_path.dirname.join(source_mapping_url).to_s
      end
    end

    def source_mapping_url(resolved_path, comment_start, comment_end)
      if asset = assembly.load_path.find(resolved_path)
        "#{comment_start}# sourceMappingURL=#{url_prefix}/#{asset.digested_path}#{comment_end}"
      else
        Propshaft.logger.warn "Removed sourceMappingURL comment for missing asset '#{resolved_path}' from #{resolved_path}"
        "#{comment_start}#{comment_end}"
      end
    end
end
