module ApiQueryLanguage
  module ActiveRecord
    module Filtering
      module Visitors
        class ConditionsNotVisitor < Visitor
          def visit(node_with_context)
            node_with_context => node, current_relation, _
            conditional = yield(node_with_context.with(node: node.node, current_relation: unscoped_root_relation))
            current_relation.merge(conditional.invert_where)
          end
        end
      end
    end
  end
end
