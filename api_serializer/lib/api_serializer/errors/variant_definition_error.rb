module ApiSerializer
  module Errors
    class VariantDefinitionError < StandardError
      def initialize(message = "Variant is invalid.")
        super
      end
    end
  end
end
