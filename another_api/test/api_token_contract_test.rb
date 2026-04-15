# frozen_string_literal: true

require "test_helper"

class AnotherApi::ApiTokenContractTest < Minitest::Test
  def setup
    AnotherApi.configuration.token_secret = "test-secret"
  end

  def teardown
    ApiToken.delete_all
    ::Bearer.delete_all
  end

  def test_token_preview_masks_the_middle_of_the_token
    bearer = ::Bearer.create!(name: "b")
    raw = "tk_abcdefgh_quite_long_token_xyz"
    token = ApiToken.create_with_raw!(raw, bearer: bearer, scopes: [])
    preview = token.token_preview
    assert preview.start_with?(raw[0, 3])
    assert preview.end_with?(raw[-3, 3])
    assert_includes preview, "*" * 12
  end

  def test_active_returns_false_when_revoked
    bearer = ::Bearer.create!(name: "b")
    token = ApiToken.create_with_raw!("tk_a_b_c_d_e_f", bearer: bearer, scopes: [], revoked_at: 1.minute.ago)
    refute token.active?
    assert token.revoked?
  end

  def test_active_returns_false_when_expired
    bearer = ::Bearer.create!(name: "b")
    token = ApiToken.create_with_raw!("tk_e_x_p_i_r_e_d", bearer: bearer, scopes: [], expires_at: 1.minute.ago)
    refute token.active?
    assert token.expired?
  end

  def test_allows_returns_true_when_a_held_scope_matches_the_request
    bearer = ::Bearer.create!(name: "b")
    token = ApiToken.create_with_raw!("tk_a_b_c_d_e", bearer: bearer, scopes: %w[api.test.widgets.list])
    requested = AnotherApi::Scope.new(group: :widgets, action: :list)
    AnotherApi.configuration.scope_prefix = "api.test."
    assert token.allows?(requested)
  end
end
