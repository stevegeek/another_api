# frozen_string_literal: true

module Test
  class PostsPolicy < AnotherApi::ApiTokenOwnershipPolicy
    private

    def scope_group_name
      :posts
    end

    def bearer_is_resource_owner?
      return nil unless record.is_a?(::Post) # collection action — fall through to scope check
      record.bearer_id == bearer.id
    end
  end
end
