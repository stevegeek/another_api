# frozen_string_literal: true

module Test
  class WidgetsPolicy < AnotherApi::ApiTokenScopedPolicy
    private

    def scope_group_name
      :widgets
    end
  end
end
