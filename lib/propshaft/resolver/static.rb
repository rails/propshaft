# frozen_string_literal: true

module Propshaft::Resolver
  class Static
    attr_reader :manifest_path, :prefix

    def initialize(manifest_path:, prefix:)
      @manifest_path = manifest_path
      @prefix = prefix
      @manifest = Propshaft::Manifest.from_path(manifest_path)
      @logical_paths_by_content_type = @manifest.logical_paths_by_content_type
    end

    def resolve(logical_path)
      if asset_path = digested_path(logical_path)
        File.join prefix, asset_path
      end
    end

    def integrity(logical_path)
      entry = @manifest[logical_path]

      entry&.integrity
    end

    def read(logical_path, encoding: "ASCII-8BIT")
      if asset_path = digested_path(logical_path)
        File.read(manifest_path.dirname.join(asset_path), encoding: encoding)
      end
    end

    def asset_paths_by_type(extension)
      @logical_paths_by_content_type[Mime::Type.lookup_by_extension(extension)] || []
    end

    private
      def digested_path(logical_path)
        entry = @manifest[logical_path]

        entry&.digested_path
      end
  end
end
