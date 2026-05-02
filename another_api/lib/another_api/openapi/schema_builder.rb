# frozen_string_literal: true

module AnotherApi
  module OpenAPI
    # Walks ApiSerializer variants and produces OpenAPI schema objects.
    #
    #   builder = SchemaBuilder.new(schema_registry)
    #   schemas = builder.build_all  # => {"UserFull" => {...}, ...}
    #
    class SchemaBuilder
      def initialize(schema_registry, configuration: AnotherApi::OpenAPI.configuration)
        @schema_registry = schema_registry
        @configuration = configuration
      end

      # Returns {openapi_name => schema_hash} for ALL variants of ALL schemas,
      # plus PaginationMetadata and FilterExpression common schemas.
      def build_all
        schemas = {}

        @schema_registry.each do |schema_name, schema_class|
          store = schema_class.schema_variants_store
          next unless store

          concrete_variants = store.variants.reject(&:abstract?)

          concrete_variants.select { |v| v.type == :serializer }.each do |variant|
            openapi_name = openapi_schema_name(schema_name, variant.name)
            schemas[openapi_name] = build_schema_from_variant(variant, variant.name)
          end

          concrete_variants.select { |v| v.type == :deserializer }.each do |variant|
            openapi_name = "#{schema_name}#{variant.name.to_s.camelize}Input"
            schemas[openapi_name] = build_schema_from_variant(variant)
          end
        end

        schemas["PaginationMetadata"] = @configuration.pagination_metadata_schema
        schemas["FilterExpression"] = @configuration.filter_expression_schema

        schemas
      end

      private

      def build_schema_from_variant(variant, current_variant_name = nil)
        current_variant_name ||= @configuration.default_variant_name
        properties = {}
        required = []

        variant.serialization.attribute_options.each do |name, attr|
          prop = TypeMapper.map(attr.type)

          prop[:readOnly] = true if attr.virtual?

          if attr.allowed_values
            values = attr.allowed_values.is_a?(Proc) ? nil : attr.allowed_values
            prop[:enum] = values if values
          end

          if attr.association?
            prop = build_association_schema(attr, current_variant_name)
          end

          properties[name] = prop

          is_nilable = attr.type.is_a?(Literal::Types::NilableType)
          required << name.to_s unless is_nilable || attr.default
        end

        schema = {type: "object", properties: properties}
        schema[:required] = required if required.any?
        schema
      end

      def build_association_schema(attr, current_variant_name)
        resolver = attr.nested_schema
        return {type: "object"} unless resolver

        target_variant = resolver.resolve_with_nested_fallback(current_variant_name)
        target_class_name = infer_schema_name_from_variant(target_variant)

        return {type: "object"} unless target_class_name

        ref = openapi_schema_name(target_class_name, target_variant.name)
        is_collection = attr.type.is_a?(Literal::Types::UnionType) || attr.type == Array

        if is_collection
          {type: "array", items: {"$ref" => "#/components/schemas/#{ref}"}}
        else
          nilable = attr.type.is_a?(Literal::Types::NilableType)
          prop = {"$ref" => "#/components/schemas/#{ref}"}
          nilable ? {oneOf: [prop, {type: "null"}]} : prop
        end
      rescue
        {type: "object"}
      end

      def openapi_schema_name(schema_name, variant_name)
        case variant_name
        when @configuration.default_variant_name
          "#{schema_name}Full"
        when :id_only
          "#{schema_name}IdOnly"
        else
          "#{schema_name}#{variant_name.to_s.camelize}"
        end
      end

      def infer_schema_name_from_variant(variant)
        @schema_registry.each do |name, klass|
          store = klass.schema_variants_store
          next unless store
          return name if store.variants.include?(variant)
        end
        nil
      end
    end
  end
end
