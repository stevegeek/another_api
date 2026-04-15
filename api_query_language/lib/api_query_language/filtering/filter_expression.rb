module ApiQueryLanguage
  module Filtering
    class FilterExpression
      def initialize(query_expression, field_to_attribute_mappings = {})
        @query_expression = query_expression
        @field_to_attribute_mappings = field_to_attribute_mappings
        parse_expression!
      end

      attr_reader :ast_root, :query_expression, :field_to_attribute_mappings

      def to_s
        "#{self.class.name}(filter_expression: '#{query_expression}')"
      end

      private

      def parse_expression!
        @ast_root = ExpressionParser.new.parse!(query_expression)
      end
    end
  end
end
