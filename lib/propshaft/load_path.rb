require "propshaft/asset"

class Propshaft::LoadPath
  attr_reader :paths

  def initialize(paths = [])
    @paths = Array(paths)
  end

  def find(asset_name)
    assets_by_path[asset_name]
  end

  def assets
    assets_by_path.values
  end

  def manifest
    Hash.new.tap do |manifest|
      assets.each do |asset|
        manifest[asset.logical_path.to_s] = asset.digested_path.to_s
      end
    end
  end

  private
    def assets_by_path
      Hash.new.tap do |mapped|
        paths.each do |path|
          all_files_from_tree(path).each do |file|
            logical_path = file.relative_path_from(path)
            mapped[logical_path.to_s] ||= Propshaft::Asset.new(file, logical_path: logical_path)
          end
        end
      end
    end

    def all_files_from_tree(path)
      path.children.flat_map { |child| child.directory? ? all_files_from_tree(child) : child }
    end
end
