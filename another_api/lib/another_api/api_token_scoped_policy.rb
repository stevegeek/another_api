module AnotherApi
  class ApiTokenScopedPolicy < ActionPolicy::Base
    authorization_targets.delete(:user)
    authorize :api_token, :bearer

    default_rule :fallback?

    pre_check :bearer_valid?

    def index? = allows?(scope_for_action(:list))
    def show? = allows?(scope_for_action(:show))
    def create? = allows?(scope_for_action(:create))
    def update? = allows?(scope_for_action(:update))
    def destroy? = allows?(scope_for_action(:delete))
    def fallback? = false
    def manage? = false

    private

    def allows?(requested_scope)
      api_token.allows?(requested_scope)
    end

    def scope_for_action(action)
      AnotherApi::Scope.new(group: scope_group_name, action: action)
    end

    def scope_group_name
      raise NoMethodError, "#{self.class}#scope_group_name must be implemented"
    end

    # Override for bearer-specific validation (e.g. deny if the bearer is
    # banned/suspended). The default is a no-op.
    def bearer_valid?
    end
  end
end
