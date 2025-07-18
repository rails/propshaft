module Propshaft
  # Manages the manifest file that maps logical asset paths to their digested counterparts.
  #
  # The manifest is used to track assets that have been processed and digested, storing
  # their logical paths, digested paths, and optional integrity hashes.
  class Manifest
    # Represents a single entry in the asset manifest.
    #
    # Each entry contains information about an asset including its logical path
    # (the original path), digested path (the path with content hash), and
    # optional integrity hash for security verification.
    class ManifestEntry
      attr_reader :logical_path, :digested_path, :integrity

      # Creates a new manifest entry.
      #
      # ==== Parameters
      #
      # * +logical_path+ - The logical path of the asset
      # * +digested_path+ - The digested path of the asset
      # * +integrity+ - The integrity hash of the asset (optional)
      def initialize(logical_path:, digested_path:, integrity:) # :nodoc:
        @logical_path = logical_path
        @digested_path = digested_path
        @integrity = integrity
      end

      # Converts the manifest entry to a hash representation.
      #
      # Returns a hash containing the +digested_path+ and +integrity+ keys.
      def to_h
        { digested_path: digested_path, integrity: integrity}
      end
    end

    class << self
      # Creates a new Manifest instance from a manifest file.
      #
      # Reads and parses a manifest file, supporting both the current format
      # (with +digested_path+ and +integrity+ keys) and the legacy format
      # (simple string values for backwards compatibility).
      #
      # ==== Parameters
      #
      # * +manifest_path+ - The path to the manifest file
      #
      # ==== Returns
      #
      # A new manifest instance populated with entries from the file.
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

    # Creates a new Manifest instance.
    #
    # ==== Parameters
    #
    # * +integrity_hash_algorithm+ - The algorithm to use for generating
    #   integrity hashes (e.g., 'sha256', 'sha384', 'sha512'). If +nil+, integrity hashes
    #   will not be generated.
    def initialize(integrity_hash_algorithm: nil)
      @integrity_hash_algorithm = integrity_hash_algorithm
      @entries = {}
    end

    # Adds an asset to the manifest.
    #
    # Creates a manifest entry from the given asset and adds it to the manifest.
    # The entry will include the asset's logical path, digested path, and optionally
    # an integrity hash if an integrity hash algorithm is configured.
    #
    # ==== Parameters
    #
    # * +asset+ - The asset to add to the manifest
    #
    # ==== Returns
    #
    # The manifest entry that was added.
    def push_asset(asset)
      entry = ManifestEntry.new(
        logical_path: asset.logical_path.to_s,
        digested_path: asset.digested_path.to_s,
        integrity: integrity_hash_algorithm && asset.integrity(hash_algorithm: integrity_hash_algorithm)
      )

      push(entry)
    end

    # Adds a manifest entry to the manifest.
    #
    # ==== Parameters
    #
    # * +entry+ - The manifest entry to add
    #
    # ==== Returns
    #
    # The entry that was added.
    def push(entry)
      @entries[entry.logical_path] = entry
    end
    alias_method :<<, :push

    # Retrieves a manifest entry by its logical path.
    #
    # ==== Parameters
    #
    # * +logical_path+ - The logical path of the asset to retrieve
    #
    # ==== Returns
    #
    # The manifest entry, or +nil+ if not found.
    def [](logical_path)
      @entries[logical_path]
    end

    # Removes a manifest entry by its logical path.
    #
    # ==== Parameters
    #
    # * +logical_path+ - The logical path of the asset to remove
    #
    # ==== Returns
    #
    # The removed manifest entry, or +nil+ if not found.
    def delete(logical_path)
      @entries.delete(logical_path)
    end

    # Converts the manifest to JSON format.
    #
    # The JSON representation maps logical paths to hash representations of
    # manifest entries, containing +digested_path+ and +integrity+ information.
    #
    # ==== Returns
    #
    # The JSON representation of the manifest.
    def to_json
      @entries.transform_values do |manifest_entry|
        manifest_entry.to_h
      end.to_json
    end

    # Transforms the values of all manifest entries using the given block.
    #
    # This method is useful for applying transformations to all manifest entries
    # while preserving the logical path keys.
    #
    # ==== Parameters
    #
    # * +block+ - A block that will receive each manifest entry
    #
    # ==== Returns
    #
    # A new hash with the same keys but transformed values.
    def transform_values(&block)
      @entries.transform_values(&block)
    end

    private
      attr_reader :integrity_hash_algorithm
  end
end
