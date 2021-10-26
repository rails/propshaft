# frozen_string_literal: true

module Propshaft
  # Generic base class for all Propshaft exceptions.
  class Error < StandardError; end

  # Raised when LoadPath cannot find the requested asset
  class MissingAssetError < Error
    def initialize(path)
      super
      @path = path
    end

    def message
      "The asset '#{@path}' was not found in the load path."
    end
  end
end
