# frozen_string_literal: true

module Propshaft
  # Generic base class for all Propshaft exceptions.
  class Error < StandardError; end

  # Raised when LoadPath cannot find the requested asset
  class MissingAssetError < Error; end
end
