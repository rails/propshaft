require "digest/sha1"
require "action_dispatch/http/mime_type"

class Propshaft::Asset
  attr_reader :path, :logical_path, :load_path

  class << self
    def extract_path_and_digest(digested_path)
      digest = digested_path[/-([0-9a-zA-Z]{7,128})\.(?!digested)([^.]|.map)+\z/, 1]
      path   = digest ? digested_path.sub("-#{digest}", "") : digested_path

      [path, digest]
    end
  end

  def initialize(path, logical_path:, load_path:)
    @path, @logical_path, @load_path = path, Pathname.new(logical_path), load_path
  end

  def content(encoding: "ASCII-8BIT")
    File.read(path, encoding: encoding)
  end

  def content_type
    Mime::Type.lookup_by_extension(logical_path.extname.from(1))
  end

  def length
    content.size
  end

  def digest
    @digest ||= Digest::SHA1.hexdigest("#{content_with_compile_references}#{load_path.version}").first(8)
  end

  def digested_path
    if already_digested?
      logical_path
    else
      logical_path.sub(/\.(\w+(\.map)?)$/) { |ext| "-#{digest}#{ext}" }
    end
  end

  def fresh?(digest)
    self.digest == digest || already_digested?
  end

  def ==(other_asset)
    logical_path.hash == other_asset.logical_path.hash
  end

  private
    def content_with_compile_references
      content + load_path.find_referenced_by(self).collect(&:content).join
    end

    def already_digested?
      logical_path.to_s =~ /-([0-9a-zA-Z_-]{7,128})\.digested/
    end
end
