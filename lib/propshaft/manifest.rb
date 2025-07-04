module Propshaft
  class Manifest
    class ManifestEntry
      attr_reader :logical_path, :digested_path, :integrity

      def initialize(logical_path:, digested_path:, integrity:)
        @logical_path = logical_path
        @digested_path = digested_path
        @integrity = integrity
      end

      def to_h
        { digested_path: digested_path, integrity: integrity}
      end
    end

    class << self
      def from_path(manifest_path)
        manifest = Manifest.new

        serialized_manifest = JSON.parse(manifest_path.read, symbolize_names: false)

        serialized_manifest.each_pair do |key, value|
          # Compatibility mode to be able to
          # read the old "simple manifest" format
          digested_path, integrity = if value.is_a?(String)
            [value, nil]
          else
            [value["digested_path"], value["integrity"]]
          end

          entry = ManifestEntry.new(
            logical_path: key, digested_path: digested_path, integrity: integrity
          )

          manifest.push(entry)
        end

        manifest
      end
    end

    def initialize(integrity_hash_algorithm: nil)
      @integrity_hash_algorithm = integrity_hash_algorithm
      @entries = {}
    end

    def push_asset(asset)
      entry = ManifestEntry.new(
        logical_path: asset.logical_path.to_s,
        digested_path: asset.digested_path.to_s,
        integrity: integrity_hash_algorithm && asset.integrity(hash_algorithm: integrity_hash_algorithm)
      )

      push(entry)
    end

    def push(entry)
      @entries[entry.logical_path] = entry
    end
    alias_method :<<, :push

    def [](logical_path)
      @entries[logical_path]
    end

    def to_json
      @entries.transform_values do |manifest_entry|
        manifest_entry.to_h
      end.to_json
    end

    private
      attr_reader :integrity_hash_algorithm
  end
end
