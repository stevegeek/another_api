# frozen_string_literal: true

require "test_helper"

class AnotherApi::OperationFailureTest < Minitest::Test
  def test_new_takes_code_message_and_extra_details
    f = AnotherApi::OperationFailure.new(:invalid_field, "is too short", :name, "more")
    assert_equal :invalid_field, f.code
    assert_equal "is too short", f.message
    assert_equal [:name, "more"], f.details
  end

  def test_deconstruct_returns_code_message_then_details
    f = AnotherApi::OperationFailure.new(:invalid_field, "is too short", :name)
    assert_equal [:invalid_field, "is too short", :name], f.deconstruct
  end

  def test_pattern_match_destructures_via_deconstruct
    f = AnotherApi::OperationFailure.new(:bad, "broken", :foo, :bar)
    case f
    in [code, msg, *rest]
      assert_equal :bad, code
      assert_equal "broken", msg
      assert_equal [:foo, :bar], rest
    else
      flunk "OperationFailure did not pattern-match as an array"
    end
  end
end
