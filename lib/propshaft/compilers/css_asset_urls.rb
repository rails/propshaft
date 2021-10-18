# frozen_string_literal: true
require "propshaft/errors"

class Propshaft::Compilers::CssAssetUrls
  attr_reader :assembly

  ASSET_URL_PATTERN = /url\(\s*["']?(?!(?:\#|data|http))([^"'\s)]+)\s*["']?\)/

  def initialize(assembly)
    @assembly = assembly
  end

  def compile(logical_path, input)
    input.gsub(ASSET_URL_PATTERN) { asset_url resolve_path(logical_path.dirname, $1) }
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

    def asset_url(resolved_path)
      if asset = assembly.load_path.find(resolved_path)
        %[url("#{assembly.config.prefix}/#{asset.digested_path}")]
      else
        raise Propshaft::MissingAssetError, "The asset '#{resolved_path}' was not found in the load path."
      end
    end
end
