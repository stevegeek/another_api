# frozen_string_literal: true

class ApiToken < ApplicationRecord
  self.table_name = "api_tokens"
  include AnotherApi::ApiTokenContract

  serialize :scopes, coder: JSON, type: Array

  # Convenience: build an in-memory token + its digest from a raw string.
  def self.create_with_raw!(raw_token, attrs = {})
    create!(
      attrs.merge(
        token_digest: AnotherApi::TokenGeneration.digest(raw_token),
        token_prefix: raw_token[0, 3],
        token_suffix: raw_token[-3, 3]
      )
    )
  end
end
