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
        { digested_path:, integrity: }
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
        integrity: @integrity_hash_algorithm && asset.integrity(hash_algorithm: @integrity_hash_algorithm)
      )

      push(entry)
    end

    def push(entry)
      @entries[entry.logical_path] = entry
    end

    def <<(asset)
      push(asset)
    end

    def [](logical_path)
      @entries[logical_path]
    end

    def to_json
      Hash.new.tap do |serialized_manifest|
        @entries.values.each do |manifest_entry|
          serialized_manifest[manifest_entry.logical_path] = manifest_entry.to_h
        end
      end.to_json
    end

    class << self
      def from_path(manifest_path)
        JSON.parse(manifest_path.read, symbolize_names: false).tap do |serialized_manifest|
          Manifest.new.tap do |manifest|
            serialized_manifest.each_pair do |key, value|
              # Compatibility mode to be able to
              # read the old "simple manifest" format
              digested_path, integrity = if value.is_a?(String)
                [value, nil]
              else
                [value["digested_path"], value["integrity"]]
              end

              entry = ManifestEntry.new(
                logical_path: key, digested_path:, integrity:
              )

              manifest.push(entry)
            end
          end
        end
      end
    end
  end
end
