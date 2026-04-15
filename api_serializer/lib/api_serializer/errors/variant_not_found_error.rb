module ApiSerializer
  module Errors
    class VariantNotFoundError < StandardError
      def initialize(message = "Variant not found")
        super
      end
    end
  end
end
