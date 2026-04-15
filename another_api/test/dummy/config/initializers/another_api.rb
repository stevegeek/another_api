# frozen_string_literal: true

AnotherApi.configure do |c|
  c.token_model = "ApiToken"
  c.token_secret = "dummy-test-secret"
  c.token_prefix = "dt"
  c.scope_prefix = "api.test."
  c.default_page_size = 5
  c.max_page_size = 50
end

AnotherApi::Scopes.define do
  scope :widgets, only: [:list, :show, :create, :update, :delete]
  scope :posts, only: [:list, :show, :create, :update, :delete]
end
