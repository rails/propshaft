module Propshaft::Resolver
  class Dynamic
    attr_reader :load_path, :prefix

    def initialize(load_path:, prefix:)
      @load_path, @prefix = load_path, prefix
    end

    def resolve(logical_path)
      if asset = load_path.find(logical_path)
        File.join prefix, asset.digested_path
      end
    end

    def read(logical_path, options = {})
      if asset = load_path.find(logical_path)
        asset.content(**options)
      end
    end
  end
end
