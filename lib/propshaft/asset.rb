require "digest/sha1"

class Propshaft::Asset
  attr_reader :path

  def initialize(path, logical_path:)
    @path = path
    @logical_path = logical_path
  end

  def content
    File.binread(path)
  end

  def content_type
    "text/plain"
  end

  def length
    content.size
  end

  def digest
    Digest::SHA1.hexdigest(content)
  end
end
