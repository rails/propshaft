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

    private
      def parsed_manifest
        @parsed_manifest ||= JSON.parse(manifest_path.read)
      end
  end
end
