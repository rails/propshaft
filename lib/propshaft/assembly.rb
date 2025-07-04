require "propshaft/manifest"
require "propshaft/load_path"
require "propshaft/resolver/dynamic"
require "propshaft/resolver/static"
require "propshaft/server"
require "propshaft/processor"
require "propshaft/compilers"
require "propshaft/compiler/css_asset_urls"
require "propshaft/compiler/js_asset_urls"
require "propshaft/compiler/source_mapping_urls"

class Propshaft::Assembly
  attr_reader :config

  def initialize(config)
    @config = config
  end

  def load_path
    @load_path ||= Propshaft::LoadPath.new(
      config.paths,
      compilers: compilers,
      version: config.version,
      file_watcher: config.file_watcher,
      integrity_hash_algorithm: config.integrity_hash_algorithm
    )
  end

  def resolver
    @resolver ||= if config.manifest_path.exist?
      Propshaft::Resolver::Static.new manifest_path: config.manifest_path, prefix: config.prefix
    else
      Propshaft::Resolver::Dynamic.new load_path: load_path, prefix: config.prefix
    end
  end

  def server
    Propshaft::Server.new(self)
  end

  def processor
    Propshaft::Processor.new \
      load_path: load_path, output_path: config.output_path, compilers: compilers, manifest_path: config.manifest_path
  end

  def compilers
    @compilers ||=
      Propshaft::Compilers.new(self).tap do |compilers|
        Array(config.compilers).each do |(mime_type, klass)|
          compilers.register mime_type, klass
        end
      end
  end

  def reveal(path_type = :logical_path)
    path_type = path_type.presence_in(%i[ logical_path path ]) || raise(ArgumentError, "Unknown path_type: #{path_type}")

    load_path.assets.collect do |asset|
      asset.send(path_type)
    end
  end
end
