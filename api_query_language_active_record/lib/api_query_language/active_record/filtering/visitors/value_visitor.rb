module ApiQueryLanguage
  module ActiveRecord
    module Filtering
      module Visitors
        class ValueVisitor < Visitor
          def visit(node_with_context)
            node_with_context => node, _, field_context
            column, value_transform, allowed_values = extract_column_transform_and_allowed_values(field_context)
            caster = column.type_caster
            value = extract_value(node)
            validate_allowed_values!(field_context, value, allowed_values)
            value = value_transform.call(value) if value_transform && value
            if caster.respond_to?(:subtype)
              collection_type(column, value, caster)
            else
              unit_type(column, value, caster)
            end
          end

          private

          def extract_column_transform_and_allowed_values(field_context)
            if field_context.respond_to?(:value_transform)
              allowed = field_context.respond_to?(:allowed_values) ? field_context.allowed_values : nil
              [field_context.column, field_context.value_transform, allowed]
            else
              [field_context, nil, nil]
            end
          end

          def validate_allowed_values!(field_context, value, allowed_values)
            return if allowed_values.nil? || allowed_values.empty? || value.nil?

            field_name = field_context.respond_to?(:column) ? field_context.column.name : "unknown"
            raise ::ApiQueryLanguage::Errors::DisallowedValueError.new(field_name, value, allowed_values) unless allowed_values.include?(value)
          end

          def collection_type(attribute, value, caster)
            raise ::ApiQueryLanguage::Errors::UnsupportedCollectionFieldTypeError.new(caster.type) unless array?(caster)

            attribute.contains([type_cast_value!(caster.subtype, value)])
          end

          def unit_type(attribute, value, caster)
            attribute.eq(type_cast_value!(caster, value))
          end

          def extract_value(node)
            raise ::ApiQueryLanguage::Errors::UnexpectedNodeTypeError.new(self, node) unless node.is_a?(::ApiQueryLanguage::Filtering::Nodes::Value)

            node.decoded_value
          end

          # PG's OID::Array constant only loads once a PG connection is established.
          # Under any other adapter (SQLite, MySQL, ...) the constant doesn't exist,
          # so no caster can be an array type — just return false.
          def array?(caster)
            return false unless defined?(::ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array)
            caster.instance_of?(::ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array)
          end

          def type_cast_value!(caster, value)
            ::ApiQueryLanguage::Filtering::Fields::FilterValueCaster.new(caster).cast(value) unless value.nil?
          end
        end
      end
    end
  end
end
