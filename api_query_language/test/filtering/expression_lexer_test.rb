require "test_helper"

module ApiQueryLanguage
  module Filtering
    class ExpressionLexerTest < ::ApiQueryLanguageTestCase
      def setup
        # We are going go override a class method so create a new class
        @lexer = Class.new(ExpressionParser).new

        @lexer.class.define_method :do_parse do
          tokens = []
          while (token = next_token)
            tokens << token
          end
          tokens
        end
      end

      def test_field_token
        token = @lexer.parse!("simple_test:").first
        assert_equal :FIELD, token[0]
        assert_equal "simple_test", token[1]
      end

      def test_field_token_with_nesting
        token = @lexer.parse!("my_model.simple_test:").first
        assert_equal :FIELD, token[0]
        assert_equal "my_model.simple_test", token[1]
      end

      def test_field_with_comparison_op_token
        tokens = @lexer.parse!("simple_test{gte}:")
        assert_equal 1, tokens.size
        assert_pattern { tokens => [[:FIELD_WITH_COMPARISON_OP, ["simple_test", "gte"]]] }
      end

      def test_numeric_value_token
        token = @lexer.parse!("31").first
        assert_equal :ENCODED_VALUE, token[0]
        assert_equal "31", token[1]
      end

      def test_encoded_value_token
        token = @lexer.parse!("value1%7Cvalue2").first
        assert_equal :ENCODED_VALUE, token[0]
        assert_equal "value1%7Cvalue2", token[1]
      end

      def test_and_condition_token
        token = @lexer.parse!("[and]").first
        assert_equal :AND_CONDITION, token[0]
        assert_equal "[and]", token[1]
      end

      def test_or_condition_token
        token = @lexer.parse!("[or]").first
        assert_equal :OR_CONDITION, token[0]
        assert_equal "[or]", token[1]
      end

      def test_or_capital_condition_token
        token = @lexer.parse!("[OR]").first
        assert_equal :OR_CONDITION, token[0]
        assert_equal "[OR]", token[1]
      end

      def test_not_condition_token
        token = @lexer.parse!("[not]").first
        assert_equal :NOT_CONDITION, token[0]
        assert_equal "[not]", token[1]
      end

      def test_group_start_token
        token = @lexer.parse!("(").first
        assert_equal :GROUP_START, token[0]
        assert_equal "(", token[1]
      end

      def test_group_end_token
        token = @lexer.parse!(")").first
        assert_equal :GROUP_END, token[0]
        assert_equal ")", token[1]
      end

      def test_value_or_token
        token = @lexer.parse!("|").first
        assert_equal :VALUE_OR, token[0]
        assert_equal "|", token[1]
      end

      def test_value_and_token
        token = @lexer.parse!("&").first
        assert_equal :VALUE_AND, token[0]
        assert_equal "&", token[1]
      end

      def test_value_wildcard_token
        token = @lexer.parse!("*").first
        assert_equal :VALUE_WILDCARD, token[0]
        assert_equal "*", token[1]
      end
    end
  end
end
