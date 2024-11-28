# frozen_string_literal: true

require "propshaft/compiler"

class Propshaft::Compiler::CssAssetUrls < Propshaft::Compiler
  ASSET_URL_PATTERN = /url\(\s*["']?(?!(?:\#|%23|data:|http:|https:|\/\/))([^"'\s?#)]+)([#?][^"')]+)?\s*["']?\)/

  def compile(asset, input)
    input.gsub(ASSET_URL_PATTERN) { asset_url resolve_path(asset.logical_path.dirname, $1), asset.logical_path, $2, $1 }
  end

  def referenced_by(asset, references: Set.new)
    asset.content.scan(ASSET_URL_PATTERN).each do |referenced_asset_url, _|
      referenced_asset = load_path.find(resolve_path(asset.logical_path.dirname, referenced_asset_url))

      if referenced_asset && references.exclude?(referenced_asset)
        references << referenced_asset
        references.merge referenced_by(referenced_asset, references: references)
      end
    end

    references
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
      if asset = load_path.find(resolved_path)
        %[url("#{url_prefix}/#{asset.digested_path}#{fingerprint}")]
      else
        Propshaft.logger.warn "Unable to resolve '#{pattern}' for missing asset '#{resolved_path}' in #{logical_path}"
        %[url("#{pattern}")]
      end
    end
end
