module ApiQueryLanguage
  module ActiveRecord
    module Filtering
      module Visitors
        class ValueExpressionVisitor < Visitor
          def visit(node_with_context)
            node_with_context => node, current_relation, _
            node.nodes.reduce(current_relation) do |relation, child_node|
              yield(node_with_context.with(node: child_node, current_relation: relation))
            end
          end
        end
      end
    end
  end
end
