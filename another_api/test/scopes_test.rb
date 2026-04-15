# frozen_string_literal: true

require "test_helper"

class AnotherApi::ScopesTest < Minitest::Test
  def setup
    @prev_prefix = AnotherApi.configuration.scope_prefix
    AnotherApi.configuration.scope_prefix = "api.test."
    AnotherApi::Scopes.reset!
  end

  def teardown
    AnotherApi.configuration.scope_prefix = @prev_prefix
    AnotherApi::Scopes.reset!
  end

  def test_define_creates_an_all_entry_plus_one_per_action
    AnotherApi::Scopes.define do
      scope :widgets, only: %i[list show]
    end
    qualified = AnotherApi::Scopes.values
    assert_includes qualified, "api.test.widgets.all"
    assert_includes qualified, "api.test.widgets.list"
    assert_includes qualified, "api.test.widgets.show"
    refute_includes qualified, "api.test.widgets.delete"
  end

  def test_define_defaults_only_to_full_crud
    AnotherApi::Scopes.define { scope :widgets }
    %w[list show create update delete].each do |action|
      assert_includes AnotherApi::Scopes.values, "api.test.widgets.#{action}"
    end
  end

  def test_find_returns_the_scope_for_a_qualified_name
    AnotherApi::Scopes.define { scope :widgets, only: %i[list] }
    s = AnotherApi::Scopes.find("api.test.widgets.list")
    assert_equal :widgets, s.group
    assert_equal :list, s.action
  end

  def test_find_returns_nil_for_unregistered_qualified_name
    assert_nil AnotherApi::Scopes.find("api.test.no_such.list")
  end

  def test_reset_clears_the_registry
    AnotherApi::Scopes.define { scope :widgets }
    refute_empty AnotherApi::Scopes.values
    AnotherApi::Scopes.reset!
    assert_empty AnotherApi::Scopes.values
  end
end
