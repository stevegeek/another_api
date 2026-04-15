module ApiSerializer
  module Variants
    class Serializer < Variant
      def type
        :serializer
      end

      def serialize(data, context = {})
        transformer.transform(data, context)
      end
    end
  end
end
