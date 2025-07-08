module Propshaft::Resolver
  class Static
    attr_reader :manifest_path, :prefix

    def initialize(manifest_path:, prefix:)
      @manifest_path, @prefix = manifest_path, prefix
    end

    def resolve(logical_path)
      if asset_path = digested_path(logical_path)
        File.join prefix, asset_path
      end
    end

    def integrity(logical_path)
      entry = manifest[logical_path]

      entry&.integrity
    end

    def read(logical_path, encoding: "ASCII-8BIT")
      if asset_path = digested_path(logical_path)
        File.read(manifest_path.dirname.join(asset_path), encoding: encoding)
      end
    end

    private
      def manifest
        @manifest ||= Propshaft::Manifest.from_path(manifest_path)
      end

      def digested_path(logical_path)
        entry = manifest[logical_path]

        entry&.digested_path
      end
  end
end
