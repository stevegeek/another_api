# frozen_string_literal: true

require "test_helper"

# Both base policy classes leave one method abstract — verify the guard fires.
class AnotherApi::PoliciesAbstractTest < Minitest::Test
  class IncompleteScopedPolicy < AnotherApi::ApiTokenScopedPolicy; end

  class IncompleteOwnershipPolicy < AnotherApi::ApiTokenOwnershipPolicy
    def scope_group_name = :widgets # provided so we get to the OWNERSHIP check
  end

  # We can't easily call the policy through ActionPolicy's machinery without
  # going through a controller, so call the private methods directly.

  def test_scoped_policy_raises_when_scope_group_name_is_not_implemented
    p = IncompleteScopedPolicy.allocate
    err = assert_raises(NoMethodError) { p.send(:scope_group_name) }
    assert_match(/scope_group_name must be implemented/, err.message)
  end

  def test_ownership_policy_raises_when_bearer_is_resource_owner_is_not_implemented
    p = IncompleteOwnershipPolicy.allocate
    err = assert_raises(NoMethodError) { p.send(:bearer_is_resource_owner?) }
    assert_match(/bearer_is_resource_owner\? must be implemented/, err.message)
  end
end
