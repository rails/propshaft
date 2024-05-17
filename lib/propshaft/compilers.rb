class Propshaft::Compilers
  attr_reader :registrations, :assembly

  def initialize(assembly)
    @assembly      = assembly
    @registrations = Hash.new
  end

  def register(mime_type, klass)
    registrations[mime_type] ||= []
    registrations[mime_type] << klass
  end

  def any?
    registrations.any?
  end

  def compilable?(asset)
    registrations[asset.content_type.to_s].present?
  end

  def compile(asset)
    if relevant_registrations = registrations[asset.content_type.to_s]
      asset.content.dup.tap do |input|
        relevant_registrations.each do |compiler|
          input.replace compiler.new(assembly).compile(asset, input)
        end
      end
    else
      asset.content
    end
  end

  def referenced_by(asset)
    Set.new.tap do |references|
      if relevant_registrations = registrations[asset.content_type.to_s]
        relevant_registrations.each do |compiler|
          references.merge compiler.new(assembly).referenced_by(asset)
        end
      end
    end
  end
end
