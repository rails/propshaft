require "propshaft/asset"

class Propshaft::LoadPath
  attr_reader :paths, :compilers, :version

  def initialize(paths = [], compilers:, version: nil)
    @paths, @compilers, @version = dedup(paths), compilers, version
  end

  def find(asset_name)
    assets_by_path[asset_name]
  end

  def find_referenced_by(asset)
    compilers.referenced_by(asset).delete(self)
  end

  def assets
    assets_by_path.values
  end

  def asset_paths_by_type(content_type)
    (@cached_asset_paths_by_type ||= Hash.new)[content_type] ||=
      extract_logical_paths_from(assets.select { |a| a.content_type == Mime::EXTENSION_LOOKUP[content_type] })
  end

  def asset_paths_by_glob(glob)
    (@cached_asset_paths_by_glob ||= Hash.new)[glob] ||=
      extract_logical_paths_from(assets.select { |a| a.path.fnmatch?(glob) })
  end

  def manifest
    Hash.new.tap do |manifest|
      assets.each do |asset|
        manifest[asset.logical_path.to_s] = asset.digested_path.to_s
      end
    end
  end

  # Returns a file watcher object configured to clear the cache of the load_path
  # when the directories passed during its initialization have changes. This is used in development
  # and test to ensure the map caches are reset when javascript files are changed.
  def cache_sweeper
    @cache_sweeper ||= begin
      exts_to_watch  = Mime::EXTENSION_LOOKUP.map(&:first)
      files_to_watch = Array(paths).collect { |dir| [ dir.to_s, exts_to_watch ] }.to_h
      mutex = Mutex.new

      Rails.application.config.file_watcher.new([], files_to_watch) do
        mutex.synchronize do
          clear_cache
          seed_cache
        end
      end
    end
  end

  private
    def assets_by_path
      @cached_assets_by_path ||= Hash.new.tap do |mapped|
        paths.each do |path|
          without_dotfiles(all_files_from_tree(path)).each do |file|
            logical_path = file.relative_path_from(path)
            mapped[logical_path.to_s] ||= Propshaft::Asset.new(file, logical_path: logical_path, load_path: self)
          end if path.exist?
        end
      end
    end

    def all_files_from_tree(path)
      path.children.flat_map { |child| child.directory? ? all_files_from_tree(child) : child }
    end

    def extract_logical_paths_from(assets)
      assets.collect { |asset| asset.logical_path.to_s }.sort
    end

    def without_dotfiles(files)
      files.reject { |file| file.basename.to_s.starts_with?(".") }
    end

    def clear_cache
      @cached_assets_by_path = nil
      @cached_asset_paths_by_type = nil
      @cached_asset_paths_by_glob = nil
    end

    def seed_cache
      assets_by_path
    end

    def dedup(paths)
      paths   = Array(paths).map { |path| Pathname.new(path) }
      deduped = [].tap do |deduped|
        paths.sort.each { |path| deduped << path if deduped.blank? || !path.to_s.start_with?(deduped.last.to_s) }
      end

      paths & deduped
    end
end
