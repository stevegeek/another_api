# frozen_string_literal: true

require "test_helper"

class AnotherApi::ScopeTest < Minitest::Test
  def setup
    AnotherApi.configuration.scope_prefix = "api.test."
  end

  def test_initialize_defaults_action_to_all
    s = AnotherApi::Scope.new(group: :widgets)
    assert_equal :widgets, s.group
    assert_equal :all, s.action
  end

  def test_initialize_rejects_unknown_action
    assert_raises(ArgumentError) { AnotherApi::Scope.new(group: :widgets, action: :totally_made_up) }
  end

  def test_parse_round_trip
    s = AnotherApi::Scope.parse("api.test.widgets.list")
    assert_equal :widgets, s.group
    assert_equal :list, s.action
    assert_equal "api.test.widgets.list", s.qualified_name
  end

  def test_parse_handles_dotted_group_names
    s = AnotherApi::Scope.parse("api.test.account.users.show")
    assert_equal :"account.users", s.group
    assert_equal :show, s.action
  end

  def test_parse_raises_for_malformed_strings
    assert_raises(ArgumentError) { AnotherApi::Scope.parse("oneword") }
  end

  def test_matches_returns_true_for_exact_action_match
    held = AnotherApi::Scope.new(group: :widgets, action: :list)
    requested = AnotherApi::Scope.new(group: :widgets, action: :list)
    assert held.matches?(requested)
  end

  def test_matches_returns_true_for_all_action_against_specific
    held = AnotherApi::Scope.new(group: :widgets, action: :all)
    requested = AnotherApi::Scope.new(group: :widgets, action: :delete)
    assert held.matches?(requested)
  end

  def test_matches_returns_false_for_different_groups
    held = AnotherApi::Scope.new(group: :widgets, action: :list)
    requested = AnotherApi::Scope.new(group: :gadgets, action: :list)
    refute held.matches?(requested)
  end

  def test_matches_returns_false_for_specific_held_against_different_action
    held = AnotherApi::Scope.new(group: :widgets, action: :list)
    requested = AnotherApi::Scope.new(group: :widgets, action: :delete)
    refute held.matches?(requested)
  end

  def test_inspect_is_human_readable
    assert_equal "#<AnotherApi::Scope widgets.list>",
      AnotherApi::Scope.new(group: :widgets, action: :list).inspect
  end
end
