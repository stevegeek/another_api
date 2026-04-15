module ApiSerializer
  module Variants
    class Variant
      def initialize(name:, serialization:, inherits: nil)
        @name = name
        @serialization = serialization
        @transformer = serialization.transformer
        @inherits = inherits
      end

      attr_reader :name, :serialization, :transformer, :inherits

      def transform(data, context = {})
        transformer.transform(data, context)
      end

      def attribute_names = serialization.attribute_names
      def composed_with = serialization.composed_with
      def reflect_on(name) = serialization.reflect_on(name)
      def filtering_mapped_attributes(**opts) = serialization.filtering_mapped_attributes(**opts)
      def sorting_mapped_attributes(**opts) = serialization.sorting_mapped_attributes(**opts)

      def resolved_name
        abstract? ? :"abstract_#{name}" : name
      end

      def abstract?
        false
      end

      def eql?(other)
        other.class == self.class && other.name == name && serialization == other.serialization
      end

      def ==(other)
        eql?(other)
      end
    end
  end
end
