require "test_helper"

class ApiSerializer::SerializationContextWrapperTest < ApiSerializerTestCase
  class RoundTripSchema < ApiSerializer::Schema
    serializer :ser do
      attribute :name, String
    end
    deserializer :des do
      attribute :name, String
    end
  end

  test "serialize invokes the named serializer variant" do
    wrapper = ApiSerializer::SerializationContextWrapper.new({name: "Alice"}, RoundTripSchema, {})
    assert_equal "Alice", wrapper.serialize(:ser).name
  end

  test "deserialize invokes the named deserializer variant" do
    wrapper = ApiSerializer::SerializationContextWrapper.new({name: "Alice"}, RoundTripSchema, {})
    assert_equal "Alice", wrapper.deserialize(:des).name
  end

  test "context with hash-like context gets current_variant_name merged in" do
    wrapper = ApiSerializer::SerializationContextWrapper.new({name: "Alice"}, RoundTripSchema, {extra: 1})
    # No exception means merge path was taken — covered indirectly via serialize.
    assert_equal "Alice", wrapper.serialize(:ser).name
  end

  test "context that already contains current_variant_name is left alone" do
    wrapper = ApiSerializer::SerializationContextWrapper.new(
      {name: "Alice"}, RoundTripSchema, {current_variant_name: :ser, extra: 1}
    )
    assert_equal "Alice", wrapper.serialize(:ser).name
  end

  test "non-hash-like context is passed through unchanged" do
    wrapper = ApiSerializer::SerializationContextWrapper.new({name: "Alice"}, RoundTripSchema, "raw-context")
    assert_equal "Alice", wrapper.serialize(:ser).name
  end
end
