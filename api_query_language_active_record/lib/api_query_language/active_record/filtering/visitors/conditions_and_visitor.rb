module ApiQueryLanguage
  module ActiveRecord
    module Filtering
      module Visitors
        class ConditionsAndVisitor < Visitor
          def visit(node_with_context)
            node_with_context => node, current_relation, _
            node.nodes.reduce(current_relation) do |relation, child_node|
              condition = yield(node_with_context.with(node: child_node, current_relation: relation))
              relation.merge(condition)
            end
          end
        end
      end
    end
  end
end
