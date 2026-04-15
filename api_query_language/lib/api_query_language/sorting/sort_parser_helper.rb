require "uri"

module ApiQueryLanguage
  module Sorting
    module SortParserHelper
      def lexer
        @lexer ||= ExpressionLexer.new
      end

      def parse_field(tokens)
        tokens.join
      end

      def parse_field_sort(tokens)
        Nodes::FieldSort.new(*tokens)
      end

      def parse_join_sort_expression(tokens)
        sort, _sep, expression = tokens
        [sort].concat(expression)
      end

      def parse_single_sort_expression(tokens)
        tokens
      end
    end
  end
end
