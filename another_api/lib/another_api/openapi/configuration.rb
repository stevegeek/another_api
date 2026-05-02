# frozen_string_literal: true

module AnotherApi
  module OpenAPI
    class Configuration
      attr_accessor :title, :description, :version, :path_prefix,
        :schema_namespace_prefix, :default_variant_name,
        :additional_discovery_variants,
        :controllers_glob, :eager_load_controllers,
        :watched_dirs, :info_extra, :servers,
        :security_schemes, :security,
        :common_parameters,
        :pagination_metadata_schema, :filter_expression_schema,
        :error_response_content

      attr_reader :concern_map

      def initialize
        @title = "API"
        @description = nil
        @version = "1.0.0"
        @path_prefix = ""

        # Empty string means "no namespace stripping": every ApiSerializer::Schema
        # subclass referenced via api_action(schema:) is included, but no
        # ObjectSpace auto-discovery happens. Set to a string like
        # "MyApp::Schemas::V1::" to opt into auto-discovery of nested schemas.
        @schema_namespace_prefix = ""

        @default_variant_name = :full
        @additional_discovery_variants = [:minimal]

        @controllers_glob = "app/controllers/**/*_controller.rb"
        @eager_load_controllers = true

        # Paths under Rails.root that SpecRenderer watches for mtime changes
        # to invalidate its dev-mode cache.
        @watched_dirs = ["app/controllers"]

        @info_extra = {}
        @servers = nil

        @security_schemes = AnotherApi::OpenAPI::CommonSchemas.default_security_schemes
        @security = [{bearerAuth: []}]

        @common_parameters = AnotherApi::OpenAPI::CommonSchemas.default_parameters
        @pagination_metadata_schema = AnotherApi::OpenAPI::CommonSchemas.default_pagination_metadata
        @filter_expression_schema = {type: "string", description: "Filter expression. See API documentation for syntax."}
        @error_response_content = AnotherApi::OpenAPI::CommonSchemas.default_error_response

        # Default concerns shipped with another_api. Users can register their
        # own app-level concern modules with #register_concern.
        @concern_map = {
          "AnotherApi::Paginated" => :paginated,
          "AnotherApi::FilteredAndSorted" => :filtered_and_sorted,
          "AnotherApi::SchemaConfigurable" => :schema_configurable
        }
      end

      def register_concern(module_name, key)
        @concern_map = @concern_map.merge(module_name.to_s => key.to_sym)
      end
    end

    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def reset_configuration!
        @configuration = Configuration.new
      end
    end
  end
end
