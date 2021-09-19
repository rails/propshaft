module Propshaft::Resolver
  class Dynamic
    attr_reader :path, :prefix

    def initialize(load_path:, prefix:)
      @load_path, @prefix = prefix, load_path
    end

    def resolve(logical_path)
      if asset = load_path.find(path)
        File.join prefix, asset.logical_path
      end
    end
  end
end
