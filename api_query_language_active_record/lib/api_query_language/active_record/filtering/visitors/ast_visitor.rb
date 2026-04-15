module ApiQueryLanguage
  module ActiveRecord
    module Filtering
      module Visitors
        class AstVisitor < Visitor
          VISITOR_MAP = {
            ApiQueryLanguage::Filtering::Nodes::Conditions => ConditionsVisitor,
            ApiQueryLanguage::Filtering::Nodes::ConditionsAnd => ConditionsAndVisitor,
            ApiQueryLanguage::Filtering::Nodes::ConditionsGroup => ConditionsGroupVisitor,
            ApiQueryLanguage::Filtering::Nodes::ConditionsNot => ConditionsNotVisitor,
            ApiQueryLanguage::Filtering::Nodes::ConditionsOr => ConditionsOrVisitor,
            ApiQueryLanguage::Filtering::Nodes::Field => FieldVisitor,
            ApiQueryLanguage::Filtering::Nodes::FieldComparison => FieldComparisonVisitor,
            ApiQueryLanguage::Filtering::Nodes::Root => RootVisitor,
            ApiQueryLanguage::Filtering::Nodes::Value => ValueVisitor,
            ApiQueryLanguage::Filtering::Nodes::ValueExpression => ValueExpressionVisitor,
            ApiQueryLanguage::Filtering::Nodes::ValueExpressionAnd => ValueExpressionAndVisitor,
            ApiQueryLanguage::Filtering::Nodes::ValueExpressionOr => ValueExpressionOrVisitor,
            ApiQueryLanguage::Filtering::Nodes::ValueWithWildcard => ValueWithWildcardVisitor
          }.freeze

          def initialize(query_context)
            @visited_nodes = 0
            @query_context = query_context
            super
          end

          def walk(node)
            @visited_nodes = 0
            visit(NodeWithContext.new(node: node, current_relation: @query_context.root_relation, context: nil))
          end

          private

          def visit(node_with_context)
            node_visited!(node_with_context)

            visitor = visitor_class(node_with_context).new(@query_context)
            visitor.visit(node_with_context) do |child_node_with_context|
              node_visited!(child_node_with_context)
              visit(child_node_with_context)
            end
          end

          def visitor_class(node_with_context)
            VISITOR_MAP.fetch(node_with_context.node.class) do
              raise "No visitor found for #{node_with_context.node.class.name}"
            end
          end

          def node_visited!(node_with_context)
            raise "Cyclical reference detected in Filter Query AST - latest node - #{node_with_context}" if @visited_nodes > 1_000
            @visited_nodes += 1
          end
        end
      end
    end
  end
end
