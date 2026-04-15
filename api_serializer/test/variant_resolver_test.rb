require "test_helper"

class ApiSerializer::VariantResolverTest < ApiSerializerTestCase
  class MySchema < ApiSerializer::Schema
    serializer :test do
      attribute :id, Integer
    end
  end

  setup do
    @variant = MySchema.serializer(:test)
    @variant_resolver = ApiSerializer::VariantResolver.new(MySchema.schema_variants_store, :serializer)
  end

  test "resolve method" do
    resolved_variant = @variant_resolver.resolve(:test)
    assert_equal @variant, resolved_variant
  end

  test "raises error when variant not found" do
    assert_raises(ApiSerializer::Errors::VariantNotFoundError) do
      @variant_resolver.resolve(:not_found)
    end
  end

  # --- resolve_with_nested_fallback ---

  test "resolve_with_nested_fallback returns the requested variant when it exists" do
    resolved = @variant_resolver.resolve_with_nested_fallback(:test)
    assert_equal @variant, resolved
  end

  test "resolve_with_nested_fallback falls back to :nested when requested variant is missing" do
    schema = Class.new(ApiSerializer::Schema) do
      serializer :id_only do
        attribute :id, Integer
      end
      serializer :nested do
        attribute :id, Integer
        attribute :name, String
      end
    end
    resolver = ApiSerializer::VariantResolver.new(schema.schema_variants_store, :serializer)

    result = resolver.resolve_with_nested_fallback(:full)
    assert_equal :nested, result.name
  end

  test "resolve_with_nested_fallback falls back to :minimal when :nested also missing" do
    schema = Class.new(ApiSerializer::Schema) do
      serializer :id_only do
        attribute :id, Integer
      end
      serializer :minimal do
        attribute :id, Integer
        attribute :name, String
      end
    end
    resolver = ApiSerializer::VariantResolver.new(schema.schema_variants_store, :serializer)

    result = resolver.resolve_with_nested_fallback(:full)
    assert_equal :minimal, result.name
  end

  test "resolve_with_nested_fallback falls back to :id_only as last resort" do
    schema = Class.new(ApiSerializer::Schema) do
      serializer :id_only do
        attribute :id, Integer
      end
    end
    resolver = ApiSerializer::VariantResolver.new(schema.schema_variants_store, :serializer)

    result = resolver.resolve_with_nested_fallback(:full)
    assert_equal :id_only, result.name
  end

  test "resolve_with_nested_fallback raises when no fallback variant exists" do
    schema = Class.new(ApiSerializer::Schema) do
      serializer :custom_only do
        attribute :id, Integer
      end
    end
    resolver = ApiSerializer::VariantResolver.new(schema.schema_variants_store, :serializer)

    assert_raises(ApiSerializer::Errors::VariantNotFoundError) do
      resolver.resolve_with_nested_fallback(:full)
    end
  end

  test "resolve_with_nested_fallback skips the requested variant in the fallback chain" do
    # Requesting :nested which doesn't exist — should skip :nested in fallbacks, land on :minimal
    schema = Class.new(ApiSerializer::Schema) do
      serializer :id_only do
        attribute :id, Integer
      end
      serializer :minimal do
        attribute :id, Integer
      end
    end
    resolver = ApiSerializer::VariantResolver.new(schema.schema_variants_store, :serializer)

    result = resolver.resolve_with_nested_fallback(:nested)
    assert_equal :minimal, result.name
  end
end
