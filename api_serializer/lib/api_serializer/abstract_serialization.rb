module ApiSerializer
  # Parent class for serialization templates produced by serializer_template /
  # deserializer_template. Never instantiated — only used as a parent so that
  # VariantBuilder can distinguish abstract templates from concrete variants
  # via `klass < AbstractSerialization`.
  class AbstractSerialization < Serialization
  end
end
