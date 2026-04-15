module ApiQueryLanguage
  module Errors
    class InvalidFieldError < Error
      def initialize(name)
        super("Unexpected field name in #{name}.")
      end
    end
  end
end
