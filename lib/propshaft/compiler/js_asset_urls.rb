# frozen_string_literal: true

require "propshaft/compiler"

class Propshaft::Compiler::JsAssetUrls < Propshaft::Compiler
  ASSET_URL_PATTERN = /((?:import|export)(?:\s*|[^]*?from\s*))(?:["']((?:\.\/|\.\.\/|\/)[^"']+)["'])/

  def compile(logical_path, input)
    input.gsub(ASSET_URL_PATTERN) { asset_url resolve_path(logical_path.dirname, $2), logical_path, $2, $1 }
  end

  private
    def resolve_path(directory, filename)
      if filename.start_with?("../")
        Pathname.new(directory + filename).relative_path_from("").to_s
      elsif filename.start_with?("/")
        filename.delete_prefix("/").to_s
      else
        (directory + filename.delete_prefix("./")).to_s
      end
    end

    def asset_url(resolved_path, logical_path, pattern, import)
      if asset = assembly.load_path.find(resolved_path)
        %[#{import} "#{url_prefix}/#{asset.digested_path} /* hello */"]
      else
        Propshaft.logger.warn "Unable to resolve '#{pattern}' for missing asset '#{resolved_path}' in #{logical_path}"
        %[#{import} "#{pattern}" /* world */]
      end
    end
end
