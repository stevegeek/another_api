# frozen_string_literal: true

module AnotherApi
  module OpenAPI
    # Converts Ruby/Literal types to OpenAPI 3.1 type objects.
    #
    #   TypeMapper.map(String)            # => {type: "string"}
    #   TypeMapper.map(_Boolean)          # => {type: "boolean"}
    #   TypeMapper.map(_Nilable(String))  # => {type: ["string", "null"]}
    #
    class TypeMapper
      def self.map(type)
        case type
        when ->(t) { t == String } then {type: "string"}
        when ->(t) { t == Integer } then {type: "integer"}
        when ->(t) { t == Numeric || t == Float } then {type: "number"}
        when ->(t) { t == Time } then {type: "string", format: "date-time"}
        when ->(t) { t == Hash } then {type: "object"}
        when ->(t) { t == Array } then {type: "array", items: {type: "string"}}
        when ->(t) { t.is_a?(Literal::Types::BooleanType) }
          {type: "boolean"}
        when ->(t) { t.is_a?(Literal::Types::NilableType) }
          inner = map(type.instance_variable_get(:@type))
          if inner[:type].is_a?(String)
            inner.merge(type: [inner[:type], "null"])
          elsif inner[:type].is_a?(Array)
            inner.merge(type: (inner[:type] + ["null"]).uniq)
          else
            inner
          end
        when ->(t) { t.is_a?(Literal::Types::ArrayType) }
          inner_type = type.instance_variable_get(:@type) || String
          {type: "array", items: map(inner_type)}
        else
          {type: "string"}
        end
      end
    end
  end
end
