require "digest/sha1"
require "action_dispatch/http/mime_type"

class Propshaft::Asset
  attr_reader :path, :logical_path, :version
  attr_accessor :dependencies, :dependency_fingerprint

  def initialize(path, logical_path:, version: nil)
    @path, @logical_path, @version = path, Pathname.new(logical_path), version
    @dependencies = nil
    @dependency_fingerprint = nil
  end

  def content
    File.binread(path)
  end

  def content_type
    Mime::Type.lookup_by_extension(logical_path.extname.from(1))
  end

  def may_depend?
    content_type&.symbol == :css
  end

  def length
    content.size
  end

  # A dependency aware digest can be calculated for any asset that has no dependencies or
  # that has had its dependency fingerprint set by DependencyTree.
  # If it's too soon, we can still calculate the digest based on file contents,
  # but there won't be any dependency cache busting.
  def digest_too_soon?
    may_depend? && dependencies&.any? && !dependency_fingerprint
  end

  def digest
    @digest ||= begin
      Propshaft.logger.warn("digest dependencies not ready for #{logical_path}") if digest_too_soon?
      Digest::SHA1.hexdigest("#{content}#{version}#{dependency_fingerprint}").first(8)
    end
  end

  def digested_path
    if already_digested?
      logical_path
    else
      logical_path.sub(/\.(\w+)$/) { |ext| "-#{digest}#{ext}" }
    end
  end

  def fresh?(digest)
    self.digest == digest || already_digested?
  end

  def ==(other_asset)
    logical_path.hash == other_asset.logical_path.hash
  end

  private
    def already_digested?
      logical_path.to_s =~ /-([0-9a-zA-Z_-]{7,128})\.digested/
    end
end
