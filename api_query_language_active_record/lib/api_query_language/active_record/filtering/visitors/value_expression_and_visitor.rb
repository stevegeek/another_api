module ApiQueryLanguage
  module ActiveRecord
    module Filtering
      module Visitors
        class ValueExpressionAndVisitor < Visitor
          def visit(node_with_context)
            node_with_context => node, current_relation, _
            node.nodes.reduce(current_relation) do |rel, child_node|
              arel_node = yield(node_with_context.with(node: child_node))
              rel.where(arel_node)
            end
          end
        end
      end
    end
  end
end
