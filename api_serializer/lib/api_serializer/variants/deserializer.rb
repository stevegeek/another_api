module ApiSerializer
  module Variants
    class Deserializer < Variant
      def type
        :deserializer
      end

      def deserialize(data, context = {})
        transformer.transform(data, context)
      end
    end
  end
end
