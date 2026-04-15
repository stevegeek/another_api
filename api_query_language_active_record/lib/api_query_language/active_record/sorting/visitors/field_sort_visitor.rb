module ApiQueryLanguage
  module ActiveRecord
    module Sorting
      module Visitors
        class FieldSortVisitor < Visitor
          def walk(nodes)
            nodes.reduce(unscoped_root_relation) do |current_relation, node|
              visit(NodeWithContext.new(node:, current_relation:, context: nil))
            end
          end

          private

          def visit(node_with_context)
            node_with_context => node, current_relation, _

            validate_node_type!(node)
            validate_direction!(node.direction)
            mapping = mapping_to_column(current_relation).map_field(node.field_identifier)
            column, relation = mapping.deconstruct
            validate_field_type!(column.type_caster)

            apply_order_criteria(relation, column, node.direction)
          end

          def validate_node_type!(node)
            raise ::ApiQueryLanguage::Errors::UnexpectedNodeTypeError.new(self, node) unless node.is_a?(::ApiQueryLanguage::Sorting::Nodes::FieldSort)
          end

          def validate_direction!(direction)
            raise ::ApiQueryLanguage::Errors::InvalidFieldValueError.new("direction", direction) unless %w[asc desc].include?(direction)
          end

          def validate_field_type!(caster)
            raise ::ApiQueryLanguage::Errors::UnsupportedFieldTypeError.new("array of #{caster.type}") if array?(caster)
          end

          # The extra SELECT columns support DISTINCT queries — e.g. sorting by
          # entity.address.state on Cart becomes
          #   SELECT DISTINCT "carts"."id", carts.*, "addresses"."state"
          # Identifiers are quoted via the connection to prevent SQL injection
          # if a consumer-supplied mapping somehow reaches us with a tainted
          # column name.
          def apply_order_criteria(relation, column, direction)
            conn = relation.model.connection
            table = conn.quote_table_name(relation.model.table_name)
            join_table = conn.quote_table_name(column.relation.name)
            join_col = conn.quote_column_name(column.name)
            relation
              .select(relation.model.primary_key, "#{table}.*", "#{join_table}.#{join_col}")
              .order(column.send(direction))
          end

          def array?(caster)
            return false unless defined?(::ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array)
            caster.instance_of?(::ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array)
          end
        end
      end
    end
  end
end
