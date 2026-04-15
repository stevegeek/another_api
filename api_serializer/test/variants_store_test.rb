require "test_helper"

class ApiSerializer::VariantsStoreTest < ApiSerializerTestCase
  class MySerializer < ApiSerializer::Serialization
    attribute :id, Integer
  end

  setup do
    @variant1 = ApiSerializer::Variants::BaseTemplate.new(
      name: :test1,
      serialization: MySerializer
    )
    @variant2 = ApiSerializer::Variants::Serializer.new(
      name: :test2,
      serialization: MySerializer
    )
    @variants_store = ApiSerializer::VariantsStore.new([@variant1, @variant2])
  end

  test "initialize method / #variants" do
    assert_equal [@variant1, @variant2], @variants_store.variants
  end

  test "fetch method" do
    assert_equal @variant1, @variants_store.fetch(:base, :test1, abstract: true)
    assert_nil @variants_store.fetch(:base, :test2, abstract: true)
    assert_nil @variants_store.fetch(:serializer, :test1, abstract: true)
    assert_nil @variants_store.fetch(:serializer, :test1, abstract: false)
    assert_equal @variant2, @variants_store.fetch(:serializer, :test2, abstract: false)
  end

  test "fetch method raises error" do
    assert_raises(ApiSerializer::Errors::VariantNotFoundError) do
      @variants_store.fetch(:serializer, :test3, abstract: false, raise_error: true)
    end
  end

  test "fetch_with_fallback method" do
    assert_equal @variant1, @variants_store.fetch_with_fallback(:base, :test1, abstract: true)
    assert_equal @variant2, @variants_store.fetch_with_fallback(:serializer, :test2, abstract: false)
  end

  test "fetch_with_fallback method raises error" do
    assert_raises(ApiSerializer::Errors::VariantNotFoundError) do
      @variants_store.fetch_with_fallback(:serializer, :test3, abstract: false, raise_error: true)
    end
  end

  test "store method" do
    variant3 = ApiSerializer::Variants::Deserializer.new(
      name: :test3,
      serialization: MySerializer
    )
    @variants_store.store(variant3)
    assert_equal @variants_store.fetch(:deserializer, :test3, abstract: false), variant3
  end

  test "clone method" do
    cloned_store = @variants_store.clone
    assert_equal cloned_store.variants, @variants_store.variants
  end
end
