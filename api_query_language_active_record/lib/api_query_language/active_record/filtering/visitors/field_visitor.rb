module ApiQueryLanguage
  module ActiveRecord
    module Filtering
      module Visitors
        class FieldVisitor < Visitor
          # Context passed to child value visitors — carries the Arel column and an optional value transform
          FieldContext = Data.define(:column, :value_transform, :allowed_values) do
            def initialize(column:, value_transform: nil, allowed_values: nil)
              super
            end

            # Delegate type_caster so existing code that calls context.type_caster still works
            def type_caster = column.type_caster
          end

          def visit(node_with_context)
            node_with_context => node, current_relation, _
            mapping = mapping_to_column(current_relation).map_field(node.field)
            column = mapping.column
            relation = mapping.relation
            raise ::ApiQueryLanguage::Errors::InvalidFieldError.new(node.field) if column.type_caster.type.nil?
            field_context = FieldContext.new(column:, value_transform: mapping.value_transform, allowed_values: mapping.allowed_values)
            value_expression = yield(::ApiQueryLanguage::NodeWithContext.new(node.value, relation, field_context))
            if value_expression.is_a?(::Arel::Nodes::Node)
              relation.where(value_expression)
            else
              relation.merge(value_expression)
            end
          end
        end
      end
    end
  end
end
