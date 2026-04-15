module ApiSerializer
  class TypedStruct < ::Literal::Struct
    include ::Literal::Types

    AttributeReflection = Data.define(:name, :type, :reader, :positional, :default, :coercion) do
      def [](key) = send(key)
    end

    class << self
      def attribute(name, type, reader: :public, positional: false, default: nil, &coercion)
        attribute_options[name] = AttributeReflection.new(
          name:, type:, reader:, positional:, default:, coercion:
        )
        prop(name, type, positional ? :positional : :keyword,
          reader: reader || :public, writer: false, default:, &coercion)
      end

      def reflect_on(name) = attribute_options[name]
      def attribute_names = attribute_options.keys

      def attribute_options
        return @attribute_options if defined?(@attribute_options)

        @attribute_options = if superclass < TypedStruct
          superclass.attribute_options.dup
        else
          {}
        end
      end
    end

    def inspect
      "#<#{self.class.name} #{attributes.map { "#{_1}: #{_2.inspect}" }.join(", ")}>"
    end

    def merge(other, ignore_nils: false)
      raise ArgumentError, "merge requires an instance of the same TypedStruct class" unless other.instance_of?(self.class)

      other_attributes = ignore_nils ? other.attributes.reject { _2.nil? } : other.attributes
      self.class.new(**attributes.merge(other_attributes))
    end

    def attributes = to_h
  end
end
