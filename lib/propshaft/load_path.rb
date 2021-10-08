require "propshaft/asset"

class Propshaft::LoadPath
  attr_reader :paths

  def initialize(paths = [])
    @paths = Array(paths).collect { |path| Pathname.new(path) }
  end

  def find(asset_name)
    assets_by_path[asset_name]
  end

  def assets(content_types: nil)
    if content_types
      assets_by_path.values.select { |asset| asset.content_type.in?(content_types) }
    else
      assets_by_path.values
    end
  end

  def manifest
    Hash.new.tap do |manifest|
      assets.each do |asset|
        manifest[asset.logical_path.to_s] = asset.digested_path.to_s
      end
    end
  end

  # Returns an instance ActiveSupport::EventedFileUpdateChecker configured to clear the cache of the load_path
  # when the directories passed during its initialization have changes. This is used in development
  # and test to ensure the map caches are reset when javascript files are changed.
  def cache_sweeper
    @cache_sweeper ||= begin
      extensions_to_watch = Mime::EXTENSION_LOOKUP.map { |x| x.first }
      Rails.application.config.file_watcher.new([], Array(paths).collect { |dir| [dir.to_s, extensions_to_watch] }.to_h) do
        clear_cache
      end
    end
  end

  private
    def assets_by_path
      @cached_assets_by_path ||= Hash.new.tap do |mapped|
        paths.each do |path|
          all_files_from_tree(path).each do |file|
            logical_path = file.relative_path_from(path)
            mapped[logical_path.to_s] ||= Propshaft::Asset.new(file, logical_path: logical_path)
          end if path.exist?
        end
      end
    end

    def all_files_from_tree(path)
      path.children.flat_map { |child| child.directory? ? all_files_from_tree(child) : child }
    end

    def clear_cache
      @cached_assets_by_path = nil
    end
end
