require "propshaft/asset"

class Propshaft::LoadPath
  attr_reader :paths

  def initialize
    @paths = []
  end

  def append(path)
    @paths.append path
  end

  def prepend(path)
    @paths.prepend path
  end

  def find(asset_name)
    assets[asset_name]
  end

  def assets
    @assets ||= Hash.new.tap do |mapped|
      paths.each do |path|
        all_files_from_tree(path).each do |file|
          logical_path = file.relative_path_from(path)
          mapped[logical_path.to_s] ||= Propshaft::Asset.new(file, logical_path: logical_path)
        end
      end
    end
  end

  private
    def all_files_from_tree(path)
      path.children.flat_map { |child| child.directory? ? all_files_from_tree(child) : child }
    end
end
