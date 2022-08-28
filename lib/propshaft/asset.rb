require "digest/sha1"
require "action_dispatch/http/mime_type"

class Propshaft::Asset
  PREDIGESTED_REGEX = /-([0-9a-zA-Z]{7,128}\.digested)/

  attr_reader :path, :logical_path, :version

  def initialize(path, logical_path:, version: nil)
    @path         = path
    @digest       = logical_path.to_s[PREDIGESTED_REGEX, 1]
    @logical_path = Pathname.new(@digest ? logical_path.sub("-#{@digest}", "") : logical_path)
    @version      = version
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
    @digest ||= Digest::SHA1.hexdigest("#{content}#{version}")
  end

  def digested_path
    logical_path.sub(/\.(\w+)$/) { |ext| "-#{digest}#{ext}" }
  end

  def fresh?(digest)
    self.digest == digest
  end

  def ==(other_asset)
    logical_path.hash == other_asset.logical_path.hash
  end
end
