require "test_helper"

class ApiSerializer::Variants::VariantTest < ApiSerializerTestCase
  class MySerializer < ApiSerializer::Serialization
    attribute :id, Integer

    def self.schema_name
      "MySchema"
    end

    def self.attribute_definitions
      -> {}
    end

    def self.composed_with
      []
    end
  end

  setup do
    @abstract_variant = ApiSerializer::Variants::BaseTemplate.new(
      name: :test,
      serialization: MySerializer
    )
    @abstract_deserializer_variant = ApiSerializer::Variants::DeserializerTemplate.new(
      name: :test,
      serialization: MySerializer
    )

    @variant = ApiSerializer::Variants::Serializer.new(
      name: :test_not_abstract,
      serialization: MySerializer
    )
  end

  test "type_key method" do
    assert_equal @variant.type, :serializer
    assert_equal @abstract_variant.type, :base
  end

  test "resolved_name method" do
    assert_equal @variant.resolved_name, @variant.name
  end

  test "abstract? method on non abstract" do
    refute @variant.abstract?
  end

  test "abstract? method on abstract" do
    assert @abstract_variant.abstract?
    assert @abstract_deserializer_variant.abstract?
  end

  test "serialize not possible on abstract" do
    refute @abstract_variant.respond_to?(:serialize)
    refute @abstract_deserializer_variant.respond_to?(:deserialize)
  end
end
