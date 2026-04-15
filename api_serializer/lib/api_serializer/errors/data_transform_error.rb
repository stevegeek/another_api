module ApiSerializer
  module Errors
    class DataTransformError < StandardError
      def initialize(message = "The data transferred failed as the data does not abide to the schema.")
        super
      end
    end
  end
end
