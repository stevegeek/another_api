module ApiQueryLanguage
  module ActiveRecord
    module Filtering
      module Visitors
        class ConditionsGroupVisitor < Visitor
          def visit(node_with_context)
            node_with_context => node, current_relation, _
            conditional = node.nodes.reduce(unscoped_root_relation) do |relation, child_node|
              condition = yield(node_with_context.with(node: child_node, current_relation: relation))
              relation.merge(condition)
            end
            # where_clause.ast is the public-ish accessor for the combined WHERE;
            # avoids the private arel.constraints API which has shifted across AR versions.
            current_relation.where(
              arel_table.grouping(conditional.where_clause.ast)
            )
          end
        end
      end
    end
  end
end
