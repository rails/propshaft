require "digest/sha1"
require "action_dispatch/http/mime_type"

class Propshaft::Asset
  attr_reader :path, :logical_path

  def initialize(path, logical_path:)
    @path, @logical_path = path, Pathname.new(logical_path)
  end

  def content
    File.binread(path)
  end

  def content_type
    Mime::Type.lookup_by_extension(logical_path.extname.from(1))
  end

  def length
    content.size
  end

  def digest
    Digest::SHA1.hexdigest(content)
  end

  def digested_path
    if already_digested?
      logical_path
    else
      logical_path.sub(/\.(\w+)$/) { |ext| "-#{digest}#{ext}" }
    end
  end

  def ==(other_asset)
    logical_path.hash == other_asset.logical_path.hash
  end

  private
    def already_digested?
      logical_path.to_s =~ /-([0-9a-f]{7,128})\.digested\.[^.]+\z/
    end
end
