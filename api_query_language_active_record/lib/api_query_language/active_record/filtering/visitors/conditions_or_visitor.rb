module ApiQueryLanguage
  module ActiveRecord
    module Filtering
      module Visitors
        class ConditionsOrVisitor < Visitor
          def visit(node_with_context)
            node_with_context => node, current_relation, _
            nested_nodes = node.nodes

            first_condition = yield(node_with_context.with(node: nested_nodes.first))
            relation = current_relation.merge(first_condition)

            nested_nodes[1..].reduce(relation) do |rel, child_node|
              or_condition = yield(node_with_context.with(node: child_node))
              rel.or(or_condition)
            end
          end
        end
      end
    end
  end
end
