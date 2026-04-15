module ApiQueryLanguage
  module Errors
    class InvalidFieldValueError < Error
      def initialize(type, value)
        super("Unexpected node in #{type}: '#{value}' (which is a #{value.class.name}).")
      end
    end
  end
end
