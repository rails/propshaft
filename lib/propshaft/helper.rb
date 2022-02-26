module Propshaft
  include ActionView::Helpers::AssetTagHelper

  module Helper
    def compute_asset_path(path, options = {})
      Rails.application.assets.resolver.resolve(path) || raise(MissingAssetError.new(path))
    end

    def javascript_include_tag(*sources)
      options = sources.extract_options!.stringify_keys

      sources.map { |source|
        options = options.merge("integrity" => asset_integrity(source, options))
        super source, options
      }.join("\n").html_safe
    end

    protected
      def asset_integrity(path, options)
        if options["integrity"] && secure_subresource_integrity_context?
          Rails.application.assets.resolver.integrity("#{path}.js")
        end
      end

      # Only serve integrity metadata for HTTPS requests:
      #   http://www.w3.org/TR/SRI/#non-secure-contexts-remain-non-secure
      def secure_subresource_integrity_context?
        respond_to?(:request) && self.request && (self.request.local? || self.request.ssl?)
      end
  end
end
