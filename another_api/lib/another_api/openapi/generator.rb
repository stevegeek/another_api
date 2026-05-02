# frozen_string_literal: true

module AnotherApi
  module OpenAPI
    # Orchestrates OpenAPI 3.1 spec generation from ApiSerializer schemas
    # and EndpointMetadata DSL declarations on controllers.
    #
    #   spec = AnotherApi::OpenAPI::Generator.generate
    #   File.write("openapi.json", JSON.pretty_generate(spec))
    #
    class Generator
      def self.generate(configuration: AnotherApi::OpenAPI.configuration)
        new(configuration: configuration).generate
      end

      def initialize(configuration: AnotherApi::OpenAPI.configuration)
        @configuration = configuration
      end

      def generate
        eager_load_api_controllers!
        schemas = SchemaBuilder.new(schema_registry, configuration: @configuration).build_all
        paths = PathBuilder.new(api_endpoints, known_schemas: schemas.keys, configuration: @configuration).build_all

        spec = {
          openapi: "3.1.0",
          info: build_info,
          paths: paths,
          components: {
            schemas: schemas,
            securitySchemes: @configuration.security_schemes,
            parameters: @configuration.common_parameters
          },
          security: @configuration.security
        }

        servers = @configuration.servers || default_servers
        spec[:servers] = servers if servers && !servers.empty?
        spec
      end

      private

      def build_info
        {
          title: @configuration.title,
          version: @configuration.version,
          description: @configuration.description
        }.merge(@configuration.info_extra || {}).compact
      end

      def default_servers
        prefix = @configuration.path_prefix
        return [] if prefix.nil? || prefix.empty?
        [{url: prefix}]
      end

      # Ensure controllers are loaded so their EndpointMetadata registrations
      # fire. In production (eager_load=true) this is a no-op; in development
      # we need to explicitly load them.
      def eager_load_api_controllers!
        return unless @configuration.eager_load_controllers
        return unless defined?(Rails) && Rails.respond_to?(:root)

        Dir[Rails.root.join(@configuration.controllers_glob)].each do |file|
          require_dependency(file)
        end
      end

      def schema_registry
        @schema_registry ||= build_schema_registry
      end

      def build_schema_registry
        registry = {}

        # 1. Schemas explicitly referenced by endpoint declarations
        EndpointRegistry.all.each do |entry|
          next unless entry.schema_lambda
          schema_class = entry.schema_lambda.call
          next unless schema_class

          name = EndpointRegistry.schema_short_name(schema_class, configuration: @configuration)
          registry[name] = schema_class if name && !registry.key?(name)
        end

        # 2. Auto-discover nested schemas under the configured namespace prefix
        # (e.g. CartItem referenced via has_many but without its own endpoint).
        # Skipped when no namespace prefix is configured to avoid pulling in
        # unrelated schemas from the host app.
        prefix = @configuration.schema_namespace_prefix
        if prefix && !prefix.empty?
          probe_variants = [@configuration.default_variant_name, *Array(@configuration.additional_discovery_variants)].uniq
          ObjectSpace.each_object(Class).each do |klass|
            next unless klass < ApiSerializer::Schema
            next unless klass.name&.start_with?(prefix)
            next unless probe_variants.any? { |v| klass.variant?(v) }

            name = EndpointRegistry.schema_short_name(klass, configuration: @configuration)
            registry[name] = klass if name && !registry.key?(name)
          end
        end

        registry
      end

      def api_endpoints
        @api_endpoints ||= EndpointRegistry.resolved_endpoints(configuration: @configuration)
      end
    end
  end
end
