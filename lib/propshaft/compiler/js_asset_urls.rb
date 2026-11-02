# frozen_string_literal: true

require "propshaft/compiler"

class Propshaft::Compiler::JsAssetUrls < Propshaft::Compiler
  ASSET_URL_PATTERN = %r{RAILS_ASSET_URL\(\s*["']?(?!(?:\#|%23|data|http|//))([^"'\s?#)]+)([#?][^"')]+)?\s*["']?\)}

  def compile(asset, input)
    input.gsub(ASSET_URL_PATTERN) { asset_url(resolve_path(asset.logical_path.dirname, $1), asset.logical_path, $2, $1) }
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
      relative = filename.start_with?("/") ? filename.delete_prefix("/") : (directory + filename).to_s
      normalized = Pathname.new(relative).cleanpath

      # A reference that climbs out of the load path cannot be fingerprinted.
      if normalized.absolute? || normalized.to_s == ".." || normalized.to_s.start_with?("../")
        filename
      else
        normalized.to_s
      end
    end

    def asset_url(resolved_path, logical_path, fingerprint, pattern)
      asset = load_path.find(resolved_path)
      if asset
        %("#{url_prefix}/#{asset.digested_path}#{fingerprint}")
      else
        Propshaft.logger.warn("Unable to resolve '#{pattern}' for missing asset '#{resolved_path}' in #{logical_path}")
        %("#{pattern}")
      end
    end
end
