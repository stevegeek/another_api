require "test_helper"

module ApiQueryLanguage
  module Sorting
    class SortExpressionParserTest < ::ApiQueryLanguageTestCase
      def setup
        @parser = ExpressionParser.new
      end

      def test_parse
        result = @parser.parse!("my_field:asc;another.field:desc")
        assert_pattern do
          result => [
            Nodes::FieldSort("my_field", "asc"),
            Nodes::FieldSort("another.field", "desc")
          ]
        end
      end

      def test_parse_longer
        result = @parser.parse!("my_field:asc;another.field:desc;stuff:asc;more:desc")
        assert_pattern do
          result => [
            Nodes::FieldSort("my_field", "asc"),
            Nodes::FieldSort("another.field", "desc"),
            Nodes::FieldSort("stuff", "asc"),
            Nodes::FieldSort("more", "desc")
          ]
        end
      end

      def test_raises_on_expression_with_no_sort_direction
        assert_raises(Errors::InvalidExpressionError) do
          @parser.parse!("more")
        end
      end

      def test_raises_on_invalid_expression
        assert_raises(Errors::InvalidExpressionError) do
          @parser.parse!("more:")
        end
      end

      def test_raises_on_invalid_expression_longer
        assert_raises(Errors::InvalidExpressionError) do
          @parser.parse!("more:desc;invalid")
        end
      end

      def test_raises_on_invalid_sort_direction
        assert_raises(Errors::InvalidExpressionError) do
          @parser.parse!("more:invalid")
        end
      end

      def test_raises_on_invalid_field_name_expression
        assert_raises(Errors::InvalidExpressionError) do
          @parser.parse!("more..test:invalid")
        end
      end
    end
  end
end
