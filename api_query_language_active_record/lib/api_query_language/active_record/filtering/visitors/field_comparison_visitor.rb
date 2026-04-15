module ApiQueryLanguage
  module ActiveRecord
    module Filtering
      module Visitors
        class FieldComparisonVisitor < FieldVisitor
          def visit(node_with_context)
            node_with_context => node, current_relation, _
            field_name = node.field
            mapping = mapping_to_column(current_relation).map_field(field_name)
            column = mapping.column
            relation = mapping.relation
            raise ::ApiQueryLanguage::Errors::InvalidFieldError.new(node.field) if column.type_caster.type.nil?
            value_expression = node.value
            value_node = value_expression.nodes.first
            raise ::ApiQueryLanguage::Errors::UnexpectedNodeTypeError.new(self, value_node) unless value_node.is_a?(::ApiQueryLanguage::Filtering::Nodes::Value)

            raw_value = value_node.decoded_value
            raw_value = mapping.value_transform.call(raw_value) if mapping.value_transform
            value = type_cast_value!(column.type_caster, raw_value)
            relation.where(map_to_arel(column, node.comparison, value))
          end

          private

          def map_to_arel(arel, operator, value)
            case operator
            when "eq"
              arel.eq(value)
            when "ieq"
              # Portable case-insensitive LIKE: lower both sides so behaviour
              # matches across PG, MySQL, and SQLite regardless of collation.
              sanitized = ::ActiveRecord::Base.sanitize_sql_like(value.to_s)
              ::Arel::Nodes::NamedFunction.new("LOWER", [arel]).matches(sanitized.downcase)
            when "neq"
              arel.not_eq(value)
            when "gt"
              arel.gt(value)
            when "gte"
              arel.gteq(value)
            when "lt"
              arel.lt(value)
            when "lte"
              arel.lteq(value)
            else
              raise ArgumentError, "Invalid operator: #{operator}"
            end
          end

          def type_cast_value!(caster, value)
            ::ApiQueryLanguage::Filtering::Fields::FilterValueCaster.new(caster).cast(value)
          end
        end
      end
    end
  end
end
