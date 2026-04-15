module ApiQueryLanguage
  module Errors
    class UnsupportedCollectionFieldTypeError < Error
      def initialize(type)
        super("Unsupported collection type: #{type}")
      end
    end
  end
end
