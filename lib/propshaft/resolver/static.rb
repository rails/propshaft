module Propshaft::Resolver
  class Static
    attr_reader :manifest_path, :prefix

    def initialize(manifest_path:, prefix:)
      @manifest_path, @prefix = manifest_path, prefix
    end

    def resolve(logical_path)
      if asset = parsed_manifest[logical_path]
        File.join prefix, asset["digested_path"]
      end
    end

    def read(logical_path)
      if asset = parsed_manifest[logical_path]
        manifest_path.dirname.join(asset["digested_path"]).read
      end
    end

    def integrity(logical_path)
      if asset = parsed_manifest[logical_path]
        asset["integrity"]
      else
        raise Propshaft::MissingAssetError.new(logical_path)
      end
    end

    private
      def parsed_manifest
        @parsed_manifest ||= JSON.parse(manifest_path.read)
      end
  end
end
