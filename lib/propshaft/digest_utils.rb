require "digest/sha1"

module Propshaft::DigestUtils
  def without_digest(path)
    if digest = extract_digest(path)
      path.sub("-#{digest}", "")
    else
      path
    end
  end

  private
    def extract_digest(path)
      path[/-([0-9a-f]{7,128})\.[^.]+\z/, 1]
    end
end
