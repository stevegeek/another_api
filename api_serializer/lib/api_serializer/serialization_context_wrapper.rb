module ApiSerializer
  class SerializationContextWrapper
    def initialize(instance, schema, context)
      @instance = instance
      @schema = schema
      @context = context
    end

    def serialize(variant_name = :full)
      transformer = @schema.serializer_for(variant_name)
      transformer.transform(@instance, context_with_variant(variant_name))
    end

    def deserialize(variant_name = :full)
      transformer = @schema.deserializer_for(variant_name)
      transformer.transform(@instance, context_with_variant(variant_name))
    end

    private

    def context_with_variant(variant_name)
      return @context unless @context.respond_to?(:key?)
      return @context if @context.key?(:current_variant_name)
      @context.merge(current_variant_name: variant_name)
    end
  end
end
