require "uri"

module ApiQueryLanguage
  module Filtering
    module FilterParserHelper
      def lexer
        @lexer ||= ExpressionLexer.new
      end

      def parse_error_context
        " at position #{lexer.ss.pos + 1}. Did you forget to encode the value?"
      end

      def parse_query(tokens)
        Nodes::Root.new(node: tokens.first)
      end

      def parse_conditions_group(tokens)
        Nodes::ConditionsGroup.new(nodes: tokens[1..-2])
      end

      def parse_conditions_and(tokens)
        Nodes::ConditionsAnd.new(nodes: [tokens.first, tokens.last])
      end

      def parse_conditions_or(tokens)
        Nodes::ConditionsOr.new(nodes: [tokens.first, tokens.last])
      end

      def parse_condition(tokens)
        Nodes::Conditions.new(nodes: tokens)
      end

      def parse_condition_not(tokens)
        Nodes::ConditionsNot.new(node: tokens[1])
      end

      def parse_condition_field_with_comparison(tokens)
        field, comparison = tokens.first
        Nodes::FieldComparison.new(
          field:,
          comparison:,
          value: parse_value_expression(
            [
              parse_encoded_value(
                [tokens.last]
              )
            ]
          )
        )
      end

      def parse_condition_field(tokens)
        Nodes::Field.new(field: tokens.first, value: tokens.last)
      end

      def parse_condition_null_field(tokens)
        Nodes::Field.new(field: tokens.first, value: Nodes::Value.new(value: nil))
      end

      def parse_value_expression_or(tokens)
        Nodes::ValueExpressionOr.new(nodes: [
          tokens.first,
          tokens.last
        ])
      end

      def parse_value_expression_and(tokens)
        Nodes::ValueExpressionAnd.new(nodes: [
          tokens.first,
          tokens.last
        ])
      end

      def parse_value_expression(tokens)
        Nodes::ValueExpression.new(nodes: tokens)
      end

      def parse_encoded_value(tokens)
        Nodes::Value.new(value: tokens.first)
      end

      def parse_encoded_value_wildcard(tokens)
        Nodes::ValueWithWildcard.new(parts: tokens)
      end
    end
  end
end
