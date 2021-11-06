# frozen_string_literal: true

require 'strscan'
require "propshaft/errors"

class Propshaft::Compilers::CssAssetUrls
  attr_reader :assembly

  ASSET_URL_PATTERN = /url\(\s*["']?(?!(?:\#|data|http))([^"'\s)]+)\s*["']?\)/

  def initialize(assembly)
    @assembly = assembly
  end

  def compile(logical_path, input)
    ignore_comment(input) do |value|
      value.gsub(ASSET_URL_PATTERN) { asset_url resolve_path(logical_path.dirname, $1) }
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

    def asset_url(resolved_path)
      if asset = assembly.load_path.find(resolved_path)
        %[url("#{assembly.config.prefix}/#{asset.digested_path}")]
      else
        raise Propshaft::MissingAssetError.new(resolved_path)
      end
    end

    COMMENT_START = /\/\*/.freeze
    COMMENT_END = /\*\//.freeze
    REST = /.*/m.freeze

    def ignore_comment(input)
      scanner = StringScanner.new(input)
      compiled = []
      inside_comment = false

      until scanner.eos?
        if !inside_comment
          code = scanner.scan_until(COMMENT_START)
          if code
            inside_comment = true
          else
            code = scanner.scan(REST)
          end
          compiled << yield(code)
        else
          comment = scanner.scan_until(COMMENT_END)
          raise Propshaft::Error.new('Invalid style sheet.') unless comment

          inside_comment = false
          compiled << comment
        end
      end
      compiled.join('')
    end
end
