require "test_helper"

class ApiSerializer::VariantBuilderTest < ApiSerializerTestCase
  class MyModelSchema < ApiSerializer::Schema; end

  def test_build
    builder = ApiSerializer::VariantBuilder.new(schema: MyModelSchema, name: :full)
    variant = builder.build do
      attribute :id, Integer
      attribute :name, String
    end
    assert_equal :full, variant.name
    assert_equal "api_serializer/FullSerialization<ApiSerializer::VariantBuilderTest::MyModelSchema[:full]>", variant.serialization.name
    assert_equal "api_serializer/FullSerialization<ApiSerializer::VariantBuilderTest::MyModelSchema[:full]>", variant.serialization.schema_name
    assert variant.is_a?(ApiSerializer::Variants::Variant)
    assert_equal [], variant.composed_with

    assert_equal([:id, :name], variant.attribute_names)
    assert(String, variant.reflect_on(:name).type)
  end

  def test_build_with_inheritance
    parent = ApiSerializer::VariantBuilder.new(schema: MyModelSchema, name: :parent).build do
      attribute :id, Integer
    end

    variant = ApiSerializer::VariantBuilder.new(
      schema: MyModelSchema,
      name: :child,
      parent: parent
    ).build do
      attribute :name, String
    end
    assert_equal :child, variant.name
    assert_equal "api_serializer/ChildSerialization<ApiSerializer::VariantBuilderTest::MyModelSchema[:child]>", variant.serialization.name
    assert_equal "api_serializer/ChildSerialization<ApiSerializer::VariantBuilderTest::MyModelSchema[:child]> inherits from template/variant: [:parent]", variant.serialization.schema_name
    assert variant.is_a?(ApiSerializer::Variants::Serializer)
    assert variant.serialization < ApiSerializer::Serialization
    assert_equal parent, variant.inherits

    assert_equal([:id, :name], variant.attribute_names)
    assert(String, variant.reflect_on(:name).type)
  end

  def test_build_with_mixins
    mixin = ApiSerializer::VariantBuilder.new(schema: MyModelSchema, name: :mixin).build do
      attribute :mixin_attr, _Float
    end

    variant = ApiSerializer::VariantBuilder.new(
      schema: MyModelSchema,
      name: :test_variant_with_mixin,
      mixins: [mixin]
    ).build do
      attribute :id, Integer
      attribute :name, String
    end
    assert_equal :test_variant_with_mixin, variant.name
    assert_equal "api_serializer/TestVariantWithMixinSerialization<ApiSerializer::VariantBuilderTest::MyModelSchema[:test_variant_with_mixin]>", variant.serialization.name
    assert_equal "api_serializer/TestVariantWithMixinSerialization<ApiSerializer::VariantBuilderTest::MyModelSchema[:test_variant_with_mixin]> composes templates/variants: [:mixin]", variant.serialization.schema_name
    assert variant.is_a?(ApiSerializer::Variants::Serializer)
    assert variant.serialization < ApiSerializer::Serialization
    assert_equal [mixin], variant.composed_with

    assert_equal [:mixin_attr, :id, :name], variant.attribute_names
    assert(Literal::Types::ConstraintType.new(Float), variant.reflect_on(:mixin_attr).type)
  end

  test "build raises ArgumentError for an unknown variant type" do
    builder = ApiSerializer::VariantBuilder.new(schema: MyModelSchema, name: :weird, type: :totally_made_up)
    err = assert_raises(ArgumentError) { builder.build }
    assert_match(/Unknown variant type/, err.message)
  end

  test "abstract serializer_template produces an AbstractSerialization subclass" do
    template = ApiSerializer::VariantBuilder.new(
      schema: MyModelSchema, name: :base_t, abstract: true, type: :serializer
    ).build do
      attribute :id, Integer
    end
    serialization_class = template.serialization
    assert_operator serialization_class, :<, ApiSerializer::AbstractSerialization
  end
end
