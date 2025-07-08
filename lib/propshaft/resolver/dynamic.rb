module Propshaft::Resolver
  class Dynamic
    attr_reader :load_path, :prefix

    def initialize(load_path:, prefix:)
      @load_path, @prefix = load_path, prefix
    end

    def resolve(logical_path)
      if asset = find_asset(logical_path)
        File.join prefix, asset.digested_path
      end
    end

    def integrity(logical_path)
      hash_algorithm = load_path.integrity_hash_algorithm

      if hash_algorithm && (asset = find_asset(logical_path))
        asset.integrity(hash_algorithm: hash_algorithm)
      end
    end

    def read(logical_path, options = {})
      if asset = load_path.find(logical_path)
        asset.content(**options)
      end
    end

    private
      def find_asset(logical_path)
        load_path.find(logical_path)
      end
  end
end
