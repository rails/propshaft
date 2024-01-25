# frozen_string_literal: true

require "propshaft/compiler"

class Propshaft::Compiler::JsImportUrls < Propshaft::Compiler
  # Sample of syntax captured by regex:
  # Import and export declarations:
  #   import defaultExport, { export1, /* … */ } from "module-name";
  #   import defaultExport, * as name from "module-name";
  #   import "module-name";
  #   export * from "module-name";
  # Dynamic imports:
  #   import("./file.js").then((module) => ...)
  #
  # (                    # Caputre 1:
  #   (?:import|export)  # Matches import or export
  #   (?:\s*|.*?from\s*) # Matches any whitespace OR anything followed by "from" followed by any whitespace
  # )
  # (                    # Caputre 2:
  #   (?:\(\s*)?         # Optionally matches ( followed by any whitespace
  #   ["']                 # Matches " or '
  # )
  # (                    # Capture 3:
  #   (?:\.\/|\.\.\/|\/) # Matches ./ OR ../ OR /
  #   [^\/]              # Matches any character that isn't /. Prevents imports strating with relative url protocol //
  #   [^"']+             # Matches any characters that aren't " or '
  # )
  # (                    # Caputre 4:
  #   ["']               # Matches " or '
  #   (?:\s*\))?         # Optionally matches any whitespace followed by a )
  # )
  IMPORT_URL_PATTERN = /((?:import|export)(?:\s*|.*?from\s*))((?:\(\s*)?["'])((?:\.\/|\.\.\/|\/)[^\/][^"']+)(["'](?:\s*\))?)/m

  def compile(logical_path, input)
    input.gsub(IMPORT_URL_PATTERN) { asset_url resolve_path(logical_path.dirname, $3), logical_path, $3, $1, $2, $4 }
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

    def asset_url(resolved_path, logical_path, pattern, import, open, close)
      if asset = assembly.load_path.find(resolved_path)
        %[#{import}#{open}#{url_prefix}/#{asset.digested_path}#{close}]
      else
        Propshaft.logger.warn "Unable to resolve '#{pattern}' for missing asset '#{resolved_path}' in #{logical_path}"
        %[#{import}#{open}#{pattern}#{close}]
      end
    end
end
