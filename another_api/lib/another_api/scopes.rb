module AnotherApi
  class Scopes
    class << self
      def define(&block)
        dsl = DSL.new(self)
        dsl.instance_eval(&block)
      end

      def registry
        @registry ||= {}
      end

      def values
        registry.values.map(&:qualified_name)
      end

      def find(qualified_name)
        registry.values.find { |s| s.qualified_name == qualified_name }
      end

      def reset!
        @registry = {}
      end
    end

    class DSL
      def initialize(scopes_class)
        @scopes_class = scopes_class
      end

      def scope(group, only: %i[list show create update delete])
        @scopes_class.registry[:"#{group}.all"] = Scope.new(group: group, action: :all)
        only.each do |action|
          @scopes_class.registry[:"#{group}.#{action}"] = Scope.new(group: group, action: action)
        end
      rescue ArgumentError => e
        raise ArgumentError, "scope :#{group} — #{e.message}"
      end
    end
  end
end
