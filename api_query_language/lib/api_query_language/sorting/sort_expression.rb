module ApiQueryLanguage
  module Sorting
    class SortExpression
      def initialize(sort_expression, field_to_attribute_mappings = {})
        @sort_expression = sort_expression
        @field_to_attribute_mappings = field_to_attribute_mappings
        parse_expression!
      end

      attr_reader :parsed, :sort_expression, :field_to_attribute_mappings

      def to_s
        "#{self.class.name}(sort_expression: '#{sort_expression}')"
      end

      private

      def parse_expression!
        @parsed = ExpressionParser.new.parse!(sort_expression)
      end
    end
  end
end
