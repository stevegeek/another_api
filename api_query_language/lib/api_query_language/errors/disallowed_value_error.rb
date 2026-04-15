module ApiQueryLanguage
  module Errors
    class DisallowedValueError < InvalidFieldValueError
      def initialize(field, value, allowed_values)
        StandardError.instance_method(:initialize).bind_call(
          self,
          "Value '#{value}' is not allowed for field '#{field}'. Allowed values: #{allowed_values.join(", ")}."
        )
      end
    end
  end
end
