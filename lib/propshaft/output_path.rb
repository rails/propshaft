require "propshaft/asset"

class Propshaft::OutputPath
  attr_reader :path, :manifest

  def initialize(path, manifest)
    @path, @manifest = path, manifest
  end

  def clean(count, age)
    asset_versions = files.group_by { |_, attrs| attrs[:logical_path] }
    asset_versions.each do |logical_path, versions|
      current = manifest[logical_path]

      versions
        .reject { |path, _| current && path == current }
        .sort_by { |_, attrs| attrs[:mtime] }
        .reverse
        .each_with_index
        .drop_while { |(_, attrs), index| fresh_version_within_limit(attrs[:mtime], count, expires_at: age, limit: index) }
        .each { |(path, _), _| remove(path) }
    end
  end

  def files
    Hash.new.tap do |files|
      all_files_from_tree(path).each do |file|
        digested_path = file.relative_path_from(path).to_s

        digest = digested_path[/-([0-9a-zA-Z]{7,128})\.(digested\.)?([^.]|.map)+\z/, 1]
        logical_path = digest ? digested_path.sub("-#{digest}", "") : digested_path

        files[digested_path] = {
          logical_path: logical_path,
          digest: digest,
          mtime: File.mtime(file)
        }
      end
    end
  end

  private
    def fresh_version_within_limit(mtime, count, expires_at:, limit:)
      modified_at = [ 0, Time.now - mtime ].max
      modified_at < expires_at || limit < count
    end

    def remove(path)
      FileUtils.rm(@path.join(path))
      Propshaft.logger.info "Removed #{path}"
    end

    def all_files_from_tree(path)
      path.children.flat_map { |child| child.directory? ? all_files_from_tree(child) : child }
    end
end
