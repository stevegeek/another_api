require "test_helper"

class ApiSerializer::SchemaTest < ApiSerializerTestCase
  class MySchema < ApiSerializer::Schema
    base_template :base_attributes do
      attribute :id, Integer, from: :encoded_id
    end

    serializer_template :abstract_serializer, composes: [:base_attributes] do
      attribute :count, Integer, default: 0
      attribute :name, String
    end

    deserializer_template :abstract_deserializer do
      attribute :encoded_id, Integer, from: :id
      attribute :name, String
    end

    serializer :serializer_variant, inherits: :abstract_serializer do
      virtual :foobar, String, default: -> { "foobar" }
    end

    deserializer :deserializer_variant, inherits: :abstract_deserializer do
      decompose [:foobar], String, from: :baz do |v|
        [v.split(".").last]
      end
    end
  end

  setup do
    @model = {encoded_id: 1, name: "Test", ignore_me: "Ignore"}
    @serialized_model = {id: 1, count: 0, name: "Test", foobar: "foobar"}

    @deserialized_model = {encoded_id: 1, name: "Test", foobar: "foobar"}
    @data_to_deserialize = {id: 1, count: 0, name: "Test", baz: "me.foobar"}
  end

  test "serializer_for method" do
    serializer = MySchema.serializer_for(:serializer_variant)
    assert_equal @serialized_model, serializer.transform(@model).to_h
  end

  test "deserializer_for method" do
    deserializer = MySchema.deserializer_for(:deserializer_variant)
    # Note deserialzer is defined above to not have count
    assert_equal @deserialized_model, deserializer.transform(@data_to_deserialize).to_h
  end

  test "variant? method" do
    refute MySchema.variant?(:base_variant)
    refute MySchema.variant?(:non_existent_variant)
    assert MySchema.variant?(:serializer_variant)
  end

  test "raises error when variant is not found" do
    assert_raises(ApiSerializer::Errors::VariantNotFoundError) do
      MySchema.serializer_for(:non_existent_variant)
    end
  end

  test "raises error if variant inherits from multiple" do
    assert_raises(ApiSerializer::Errors::VariantDefinitionError) do
      Class.new(ApiSerializer::Schema) do
        serializer :bad_variant, inherits: [:variant1, :variant2]
      end
    end
  end
end
