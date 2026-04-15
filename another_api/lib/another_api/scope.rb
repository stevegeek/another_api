module AnotherApi
  SCOPE_ACTIONS = %i[all list show create update delete reject activate deactivate].freeze

  Scope = Data.define(:group, :action) do
    def initialize(group:, action: :all)
      raise ArgumentError, "Invalid action: #{action}" unless SCOPE_ACTIONS.include?(action.to_sym)
      super(group: group.to_sym, action: action.to_sym)
    end

    def self.parse(scope_str, prefix: AnotherApi.configuration.scope_prefix)
      stripped = scope_str.to_s.delete_prefix(prefix)
      parts = stripped.split(".")
      raise ArgumentError, "Invalid scope string: #{scope_str}" if parts.size < 2
      action = parts.pop
      group = parts.join(".")
      new(group: group.to_sym, action: action.to_sym)
    end

    def qualified_name
      "#{AnotherApi.configuration.scope_prefix}#{group}.#{action}"
    end

    def matches?(other)
      other.group == group && (action == :all || other.action == action)
    end

    def inspect
      "#<AnotherApi::Scope #{group}.#{action}>"
    end
  end
end
