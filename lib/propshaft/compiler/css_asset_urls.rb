# frozen_string_literal: true

require "propshaft/compiler"

class Propshaft::Compiler::CssAssetUrls < Propshaft::Compiler
  ASSET_URL_PATTERN = /url\(\s*["']?(?!(?:\#|%23|data|http|\/\/))([^"'\s?#)]+)([#?][^"')]+)?\s*["']?\)/

  def compile(asset)
    asset.content.gsub(ASSET_URL_PATTERN) { asset_url resolve_path(asset.logical_path.dirname, $1), asset.logical_path, $2, $1 }
  end

  def find_dependencies(asset)
    Set.new.tap do |dependencies|
      asset.content.scan(ASSET_URL_PATTERN).each do |dependent_asset_url, _|
        dependent_asset = assembly.load_path.find(resolve_path(asset.logical_path.dirname, dependent_asset_url))

        if dependencies.exclude?(dependent_asset)
          dependencies << dependent_asset
          dependencies.merge(find_dependencies(dependent_asset))
        end
      end
    end
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

    def asset_url(resolved_path, logical_path, fingerprint, pattern)
      if asset = assembly.load_path.find(resolved_path)
        %[url("#{url_prefix}/#{asset.digested_path}#{fingerprint}")]
      else
        Propshaft.logger.warn "Unable to resolve '#{pattern}' for missing asset '#{resolved_path}' in #{logical_path}"
        %[url("#{pattern}")]
      end
    end
end
