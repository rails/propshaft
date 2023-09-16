require "propshaft/load_path"
require "propshaft/resolver/dynamic"
require "propshaft/resolver/static"
require "propshaft/server"
require "propshaft/processor"
require "propshaft/compilers"
require "propshaft/compiler/css_asset_urls"
require "propshaft/compiler/source_mapping_urls"

class Propshaft::Assembly
  attr_reader :config

  def initialize(config)
    @config = config
  end

  def load_path
    @load_path ||= Propshaft::LoadPath.new(config.paths, version: config.version)
  end

  def resolver
    @resolver ||= if manifest_path.exist?
      Propshaft::Resolver::Static.new manifest_path: manifest_path, prefix: config.prefix
    else
      Propshaft::Resolver::Dynamic.new load_path: load_path, prefix: config.prefix
    end
  end

  def server
    Propshaft::Server.new(self)
  end

  def processor
    Propshaft::Processor.new \
      load_path: load_path, output_path: config.output_path, compilers: compilers
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

  private
    def manifest_path
      config.output_path.join(Propshaft::Processor::MANIFEST_FILENAME)
    end
end
