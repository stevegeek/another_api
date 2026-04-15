module ApiQueryLanguage
  module ActiveRecord
    module Filtering
      module Visitors
        class RootVisitor < Visitor
          def visit(node_with_context)
            # Simply visit the next node
            next_node = node_with_context.node.node
            yield(node_with_context.with(node: next_node))
          end
        end
      end
    end
  end
end
