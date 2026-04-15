module ApiQueryLanguage
  module Errors
    class InvalidExpressionError < Error
      def initialize(expression, reason)
        super("The expression '#{expression}' is invalid because #{reason}.")
      end
    end
  end
end
