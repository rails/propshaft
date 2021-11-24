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

      versions.reject { |path, _|
        current && path == current
      }.sort_by { |_, attrs|
        attrs[:mtime]
      }.reverse.each_with_index.drop_while { |(_, attrs), index|
        _age = [0, Time.now - attrs[:mtime]].max
        # Keep if under age or within the count limit
        _age < age || index < count
      }.each { |(path, _), _|
        # Remove old assets
        remove(path)
      }
    end
  end

  def files
    Hash.new.tap do |files|
      all_files_from_tree(path).each do |file|
        digested_path = file.relative_path_from(path)
        logical_path, digest = extract_path_and_digest(digested_path)

        files[digested_path.to_s] = {
          logical_path: logical_path.to_s,
          digest: digest,
          mtime: File.mtime(path)
        }
      end
    end
  end

  private
    def remove(path)
      FileUtils.rm(@path.join(path))
      Propshaft.logger.info "Removed #{path}"
    end

    def all_files_from_tree(path)
      path.children.flat_map { |child| child.directory? ? all_files_from_tree(child) : child }
    end

    def extract_path_and_digest(digested_path)
      digest = digested_path.to_s[/-([0-9a-f]{7,128})\.(?!digested)[^.]+\z/, 1]
      path = digest ? digested_path.sub("-#{digest}", "") : digested_path

      [path, digest]
    end
end
