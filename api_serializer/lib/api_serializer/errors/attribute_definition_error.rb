module ApiSerializer
  module Errors
    class AttributeDefinitionError < StandardError
      def initialize(message = "The attribute definition is invalid.")
        super
      end
    end
  end
end
