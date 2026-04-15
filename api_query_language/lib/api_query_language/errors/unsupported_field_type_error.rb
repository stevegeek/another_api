module ApiQueryLanguage
  module Errors
    class UnsupportedFieldTypeError < Error
      def initialize(type)
        super("Unsupported type: #{type}")
      end
    end
  end
end
