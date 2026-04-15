module ApiQueryLanguage
  module ActiveRecord
    module Filtering
      module Visitors
        class ValueExpressionOrVisitor < Visitor
          def visit(node_with_context)
            node_with_context => node, current_relation, _
            arel_node = yield(node_with_context.with(node: node.nodes.first))
            first_clause = current_relation.where(arel_node)
            node.nodes[1..].reduce(first_clause) do |rel, child_node|
              arel_node = yield(node_with_context.with(node: child_node))
              rel.or(current_relation.where(arel_node))
            end
          end
        end
      end
    end
  end
end
