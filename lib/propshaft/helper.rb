module Propshaft
  # Helper module that provides asset path resolution and integrity support for Rails applications.
  #
  # This module extends Rails' built-in asset helpers with additional functionality:
  # - Subresource Integrity (SRI) support for enhanced security
  # - Bulk stylesheet inclusion with :all and :app options
  # - Asset path resolution with proper error handling
  #
  # == Subresource Integrity (SRI) Support
  #
  # SRI helps protect against malicious modifications of assets by ensuring that
  # resources fetched from CDNs or other sources haven't been tampered with.
  #
  # SRI is automatically enabled in secure contexts (HTTPS or local development)
  # when the 'integrity' option is set to true:
  #
  #   <%= stylesheet_link_tag "application", integrity: true %>
  #   <%= javascript_include_tag "application", integrity: true %>
  #
  # This will generate integrity hashes and include them in the HTML:
  #
  #   <link rel="stylesheet" href="/assets/application-abc123.css"
  #         integrity="sha256-xyz789...">
  #   <script src="/assets/application-def456.js"
  #           integrity="sha256-uvw012..."></script>
  #
  # == Bulk Stylesheet Inclusion
  #
  # The stylesheet_link_tag helper supports special symbols for bulk inclusion:
  # - :all - includes all CSS files found in the load path
  # - :app - includes only CSS files from app/assets/**/*.css
  #
  #   <%= stylesheet_link_tag :all %>  # All stylesheets
  #   <%= stylesheet_link_tag :app %>  # Only app stylesheets
  module Helper
    # Computes the Subresource Integrity (SRI) hash for the given asset path.
    #
    # This method generates a cryptographic hash of the asset content that can be used
    # to verify the integrity of the resource when it's loaded by the browser.
    #
    #   asset_integrity("application.css")
    #   # => "sha256-xyz789abcdef..."
    def asset_integrity(path, options = {})
      path = _path_with_extname(path, options)
      Rails.application.assets.resolver.integrity(path)
    end

    # Resolves the full path for an asset, raising an error if not found.
    def compute_asset_path(path, options = {})
      Rails.application.assets.resolver.resolve(path) || raise(MissingAssetError.new(path))
    end

    # Enhanced +stylesheet_link_tag+ with integrity support and bulk inclusion options.
    #
    # In addition to the standard Rails functionality, this method supports:
    # * Automatic SRI (Subresource Integrity) hash generation in secure contexts
    # * Add an option to call +stylesheet_link_tag+ with +:all+ to include every css
    #   file found on the load path or +:app+ to include css files found in
    #   <tt>Rails.root("app/assets/**/*.css")</tt>, which will exclude lib/ and plugins.
    #
    # ==== Options
    #
    # * <tt>:integrity</tt> - Enable SRI hash generation
    #
    # ==== Examples
    #
    #   stylesheet_link_tag "application", integrity: true
    #   # => <link rel="stylesheet" href="/assets/application-abc123.css"
    #   #          integrity="sha256-xyz789...">
    #
    #   stylesheet_link_tag :all    # All stylesheets in load path
    #   stylesheet_link_tag :app    # Only app/assets stylesheets
    def stylesheet_link_tag(*sources)
      options = sources.extract_options!

      case sources.first
      when :all
        sources = all_stylesheets_paths
      when :app
        sources = app_stylesheets_paths
      end

      _build_asset_tags(sources, options, :stylesheet) { |source, opts| super(source, opts) }
    end

    # Enhanced +javascript_include_tag+ with automatic SRI (Subresource Integrity) support.
    #
    # This method extends Rails' built-in +javascript_include_tag+ to automatically
    # generate and include integrity hashes when running in secure contexts.
    #
    # ==== Options
    #
    # * <tt>:integrity</tt> - Enable SRI hash generation
    #
    # ==== Examples
    #
    #   javascript_include_tag "application", integrity: true
    #   # => <script src="/assets/application-abc123.js"
    #   #           integrity="sha256-xyz789..."></script>
    def javascript_include_tag(*sources)
      options = sources.extract_options!

      _build_asset_tags(sources, options, :javascript) { |source, opts| super(source, opts) }
    end

    # Returns a sorted and unique array of logical paths for all stylesheets in the load path.
    def all_stylesheets_paths
      Rails.application.assets.load_path.asset_paths_by_type("css")
    end

    # Returns a sorted and unique array of logical paths for all stylesheets in app/assets/**/*.css.
    def app_stylesheets_paths
      Rails.application.assets.load_path.asset_paths_by_glob("#{Rails.root.join("app/assets")}/**/*.css")
    end

    private
      # Core method that builds asset tags with optional integrity support.
      #
      # This method handles the common logic for both +stylesheet_link_tag+ and
      # +javascript_include_tag+, including SRI hash generation and HTML tag creation.
      def _build_asset_tags(sources, options, asset_type)
        options = options.stringify_keys
        integrity = _compute_integrity?(options)

        sources.map { |source|
          opts = integrity ? options.merge!('integrity' => asset_integrity(source, type: asset_type)) : options
          yield(source, opts)
        }.join("\n").html_safe
      end

      # Determines whether integrity hashes should be computed for assets.
      #
      # Integrity is only computed in secure contexts (HTTPS or local development)
      # and when explicitly requested via the +integrity+ option.
      def _compute_integrity?(options)
        if _secure_subresource_integrity_context?
          case options['integrity']
          when nil, false, true
            options.delete('integrity') == true
          end
        else
          options.delete 'integrity'
          false
        end
      end

      # Checks if the current context is secure enough for Subresource Integrity.
      #
      # SRI is only beneficial in secure contexts. Returns true when:
      # * The request is made over HTTPS (SSL), OR
      # * The request is local (development environment)
      def _secure_subresource_integrity_context?
        respond_to?(:request) && self.request && (self.request.local? || self.request.ssl?)
      end

      # Ensures the asset path includes the appropriate file extension.
      def _path_with_extname(path, options)
        "#{path}#{compute_asset_extname(path, options)}"
      end
  end
end
