# frozen_string_literal: true

# Base compiler from which other compilers can inherit
class Propshaft::Compiler
  attr_reader :assembly
  delegate :config, :load_path, to: :assembly

  def initialize(assembly)
    @assembly = assembly
  end

  # Override this in a specific compiler
  def compile(asset, input)
    raise NotImplementedError
  end

  def referenced_by(asset)
    Set.new
  end

  private
    def url_prefix
      @url_prefix ||= File.join(config.relative_url_root.to_s, config.prefix.to_s).chomp("/")
    end
end
