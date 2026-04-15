# frozen_string_literal: true

require "literal"

require_relative "api_serializer/version"

module ApiSerializer
end

require_relative "api_serializer/errors/variant_definition_error"
require_relative "api_serializer/errors/attribute_definition_error"
require_relative "api_serializer/errors/variant_not_found_error"
require_relative "api_serializer/errors/data_transform_error"

require_relative "api_serializer/attribute_options"
require_relative "api_serializer/typed_struct"
require_relative "api_serializer/target_data_structure"
require_relative "api_serializer/queryable_config"
require_relative "api_serializer/data_transformer"
require_relative "api_serializer/serialization_context_wrapper"

require_relative "api_serializer/variants/variant"
require_relative "api_serializer/variants/abstract_variant"
require_relative "api_serializer/variants/base_template"
require_relative "api_serializer/variants/serializer_template"
require_relative "api_serializer/variants/deserializer_template"
require_relative "api_serializer/variants/serializer"
require_relative "api_serializer/variants/deserializer"

require_relative "api_serializer/variants_store"
require_relative "api_serializer/variant_builder"
require_relative "api_serializer/variant_resolver"
require_relative "api_serializer/serialization"
require_relative "api_serializer/abstract_serialization"
require_relative "api_serializer/schema"
