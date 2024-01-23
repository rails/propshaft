module Propshaft::Resolver
  class Static
    attr_reader :manifest_path, :prefix

    def initialize(manifest_path:, prefix:)
      @manifest_path, @prefix = manifest_path, prefix
    end

    def resolve(logical_path)
      if asset_path = parsed_manifest[logical_path]
        File.join prefix, asset_path
      end
    end

    def read(logical_path, encoding: "ASCII-8BIT")
      if asset_path = parsed_manifest[logical_path]
        File.read(manifest_path.dirname.join(asset_path), encoding: encoding)
      end
    end

    private
      def parsed_manifest
        @parsed_manifest ||= JSON.parse(manifest_path.read, symbolize_names: false)
      end
  end
end
