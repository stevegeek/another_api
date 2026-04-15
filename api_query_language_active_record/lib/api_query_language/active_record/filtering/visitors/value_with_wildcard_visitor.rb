module ApiQueryLanguage
  module ActiveRecord
    module Filtering
      module Visitors
        class ValueWithWildcardVisitor < Visitor
          def visit(node_with_context)
            node_with_context => node, _, field_context
            column = field_context.respond_to?(:column) ? field_context.column : field_context
            caster = column.type_caster
            column.matches(type_cast_value!(caster, extract_value(node)))
          end

          private

          def extract_value(node)
            raise ::ApiQueryLanguage::Errors::UnexpectedNodeTypeError.new(self, node) unless node.is_a?(::ApiQueryLanguage::Filtering::Nodes::ValueWithWildcard)

            value = ::ActiveRecord::Base.sanitize_sql_like(node.decoded_value)
            left_op, right_op = node.wildcards.map { |w| map_operator(w) }
            "#{left_op}#{value}#{right_op}"
          end

          # Only string unit types are supported here
          def type_cast_value!(caster, value)
            ::ApiQueryLanguage::Filtering::Fields::FilterValueCaster.new(caster, supported_types: %i[string]).cast(value)
          end

          def map_operator(op)
            case op
            when "*"
              "%"
            when "+"
              "_%"
            end
          end
        end
      end
    end
  end
end
