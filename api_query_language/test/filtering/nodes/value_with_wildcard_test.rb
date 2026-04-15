require "test_helper"

module ApiQueryLanguage
  module Filtering
    module Nodes
      class ValueWithWildcardTest < ::ApiQueryLanguageTestCase
        def setup
          @value_with_star_wildcards = ValueWithWildcard.new(parts: ["*", "value", "*"])
          @value_no_wildcard = ValueWithWildcard.new(parts: ["value"])
          @value_star_wildcard_start = ValueWithWildcard.new(parts: ["*", "value"])
          @value_star_wildcard_end = ValueWithWildcard.new(parts: ["value", "*"])
          @value_with_plus_wildcards = ValueWithWildcard.new(parts: ["+", "value", "+"])
          @value_wildcard_plus_start = ValueWithWildcard.new(parts: ["+", "value"])
          @value_wildcard_plus_end = ValueWithWildcard.new(parts: ["value", "+"])
          @value_with_star_and_plus_wildcard = ValueWithWildcard.new(parts: ["*", "value", "+"])
          @value_with_plus_and_star_wildcard = ValueWithWildcard.new(parts: ["+", "value", "*"])
        end

        def test_decoded_value
          assert_equal "value", @value_with_star_wildcards.decoded_value
        end

        def test_wildcard_start
          assert @value_with_star_wildcards.wildcard_start?
          assert @value_with_plus_wildcards.wildcard_start?
          assert @value_with_plus_and_star_wildcard.wildcard_start?
          assert @value_wildcard_plus_start.wildcard_start?
          refute @value_star_wildcard_end.wildcard_start?
        end

        def test_wildcard_end
          assert @value_with_star_wildcards.wildcard_end?
          assert @value_with_star_and_plus_wildcard.wildcard_end?
          assert @value_with_plus_and_star_wildcard.wildcard_end?
          assert @value_wildcard_plus_end.wildcard_end?
          refute @value_star_wildcard_start.wildcard_end?
        end

        def test_value
          assert_equal "value", @value_with_star_wildcards.value
        end

        def test_no_wildcard
          assert_raises { @value_no_wildcard.value }
        end

        def test_wildcard_start_only
          assert_equal "value", @value_star_wildcard_start.value
          assert @value_star_wildcard_start.wildcard_start?
          refute @value_star_wildcard_start.wildcard_end?
          assert @value_wildcard_plus_start.wildcard_start?
          refute @value_wildcard_plus_start.wildcard_end?
        end

        def test_wildcard_end_only
          assert_equal "value", @value_star_wildcard_end.value
          refute @value_star_wildcard_end.wildcard_start?
          assert @value_star_wildcard_end.wildcard_end?
          refute @value_wildcard_plus_end.wildcard_start?
          assert @value_wildcard_plus_end.wildcard_end?
        end

        def test_wildcards
          assert_equal ["*", "*"], @value_with_star_wildcards.wildcards
          assert_equal ["+", "+"], @value_with_plus_wildcards.wildcards
          assert_equal ["*", "+"], @value_with_star_and_plus_wildcard.wildcards
          assert_equal ["+", "*"], @value_with_plus_and_star_wildcard.wildcards
          assert_equal ["+", nil], @value_wildcard_plus_start.wildcards
          assert_equal [nil, "+"], @value_wildcard_plus_end.wildcards
          assert_equal ["*", nil], @value_star_wildcard_start.wildcards
          assert_equal [nil, "*"], @value_star_wildcard_end.wildcards
          assert_raises { @value_no_wildcard.wildcards }
        end
      end
    end
  end
end
