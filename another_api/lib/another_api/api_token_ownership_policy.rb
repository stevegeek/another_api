module AnotherApi
  class ApiTokenOwnershipPolicy < ApiTokenScopedPolicy
    pre_check :check_bearer_ownership!

    private

    def bearer_is_resource_owner?
      raise NoMethodError, "#{self.class}#bearer_is_resource_owner? must be implemented"
    end

    def check_bearer_ownership!
      result = bearer_is_resource_owner?
      deny! if result == false
      # nil means "not applicable" (e.g. collection action) — fall through to scope check
    end
  end
end
