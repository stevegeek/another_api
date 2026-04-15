module ApiSerializer
  module Variants
    class AbstractVariant < Variant
      def abstract?
        true
      end
    end
  end
end
