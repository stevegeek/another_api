require "test_helper"

class ApiSerializer::SerializationTest < ApiSerializerTestCase
  test "attribute class method" do
    builder = ApiSerializer::VariantBuilder.new(schema: ApiSerializer::Schema, name: :test_adding_attributes)
    variant = builder.build do
      attribute :id, Integer
      attribute :name, String
      attribute :age, Float, from: "years"
    end

    attr = variant.reflect_on(:age)
    assert_equal([:id, :name, :age], variant.attribute_names)
    assert_equal Float, attr.type
    assert_equal "years", attr.from_path
  end

  test "compose attributes" do
    builder = ApiSerializer::VariantBuilder.new(schema: ApiSerializer::Schema, name: :test_adding_compose_attributes)
    variant = builder.build do
      compose :full_name, String, from: ["first_name", "last_name"] do |first_name, last_name|
        "#{first_name} #{last_name}"
      end
    end

    attr = variant.reflect_on(:full_name)
    assert_equal([:full_name], variant.attribute_names)
    assert_equal String, attr.type
    assert attr.compose?
    assert_equal ["first_name", "last_name"], attr.composed_of
  end

  test "virtual attributes" do
    builder = ApiSerializer::VariantBuilder.new(schema: ApiSerializer::Schema, name: :test_adding_virtual_attributes)
    variant = builder.build do
      virtual :total_orders_placed, Integer do |user, context|
        context[:order_count]
      end
    end

    attr = variant.reflect_on(:total_orders_placed)
    assert_equal([:total_orders_placed], variant.attribute_names)
    assert attr.virtual?
    assert_equal Integer, attr.type
    assert_equal true, attr.virtual?
  end

  #
  # test "attribute inheritance in variants" do
  #   serializer = ApiSerializer::Serializer.build_variant(ApiSerializer::Schema, :test_adding_attributes, []) do
  #     attribute :id, Integer
  #   end
  #   serializer.class_eval do
  #     attribute :name, String
  #   end
  #
  #   # Create child serializer variant, mixin parent serializer variant
  #   child_serializer = serializer.build_variant(ApiSerializer::Schema, :test_adding_attributes_child, []) do
  #     attribute :age, Float
  #   end
  #
  #   serializer.class_eval do
  #     attribute :hobby, String
  #   end
  #
  #   assert_includes serializer.attribute_names, :id
  #   assert_includes serializer.attribute_names, :name
  #   assert_equal([:id, :name, :hobby], serializer.attribute_names)
  #   assert(String, serializer.reflect_on(:hobby).type)
  #   assert_equal(ApiSerializer::Serializer::AttributeReflection, serializer.reflect_on(:id).class)
  #   assert_equal(String, serializer.reflect_on(:name).type)
  #
  #   assert_equal([:id, :name, :age], child_serializer.attribute_names)
  #   assert_equal(String, child_serializer.reflect_on(:name).type)
  #   assert_equal(Float, child_serializer.reflect_on(:age).type)
  # end
  #
  # test "attributes add to schemas they are composed with" do
  #   serializer1 = ApiSerializer::Serializer.build_variant(ApiSerializer::Schema, :test_adding_attributes, []) do
  #     attribute :id, Integer
  #   end
  #   serializer2 = ApiSerializer::Serializer.build_variant(ApiSerializer::Schema, :test_composes_with_mixin_attributes, []) do
  #     attribute :name, String
  #   end
  #
  #   # Create child serializer variant, mixin a serializer variant that adds name
  #   child_serializer = serializer1.build_variant(ApiSerializer::Schema, :test_adding_attributes_via_mixin, [serializer2]) do
  #     attribute :age, Float
  #   end
  #
  #   serializer1.class_eval do
  #     attribute :hobby, String
  #   end
  #
  #   assert_equal([:id, :hobby], serializer1.attribute_names)
  #   assert_equal([:name], serializer2.attribute_names)
  #   assert_equal([:id, :name, :age], child_serializer.attribute_names)
  #   assert_equal(String, child_serializer.reflect_on(:name).type)
  #   assert_equal(Float, child_serializer.reflect_on(:age).type)
  # end
  #
  # test "composite class method" do
  #   serializer = ApiSerializer::Serializer.build_variant(ApiSerializer::Schema, :test_adding_composites, []) do
  #     composite :name, String, of: ["first_name", "last_name"] do |record|
  #       "#{record.first_name} #{record.last_name}"
  #     end
  #   end
  #
  #   assert serializer.reflect_on(:name).composite?
  #   assert(String, serializer.reflect_on(:name).type)
  # end

  #####################

  # test "nested class method" do
  #   serializer = ApiSerializer::Serializer.build_variant(ApiSerializer::Schema, :test_adding_nested, []) do
  #     attribute :id, Integer
  #   end
  #   serializer.nested :nested, serializer
  #   assert_includes serializer.attribute_names, :nested
  # end
  #
  # test "nested_collection class method" do
  #   serializer = ApiSerializer::Serializer.build_variant(ApiSerializer::Schema, :test_adding_nested_collection, []) do
  #     attribute :id, Integer
  #   end
  #   serializer.nested_collection :nested_collection, serializer
  #   assert_includes serializer.attribute_names, :nested_collection
  # end
  #
  # test "nested_collection can serialize" do
  #   self.class.const_set(
  #     :SerializerTestMyNestedTestSchema,
  #     Class.new(ApiSerializer::Schema) do
  #       serializer :minimal do
  #         attribute :id, Integer
  #       end
  #     end
  #   )
  #   # nested_serializer_variant = ApiSerializer::Serializer.build_variant(MyNestedTestSchema, :full, [])
  #   self.class.const_set(
  #     :SerializerTestMyTestSchema,
  #     Class.new(ApiSerializer::Schema) do
  #       serializer :full do
  #         attribute :str, String
  #         nested_collection :items, SerializerTestMyNestedTestSchema.using_serializer(:minimal)
  #       end
  #     end
  #   )
  #
  #   data = {str: "Hi", items: [{id: 1}, {id: 2}]}
  #   serializer = SerializerTestMyTestSchema.serializer_for(:full, data)
  #
  #   assert_equal(data, serializer.to_hash)
  # end
  #

  # test "new_serializer_variant class method" do
  #   serializer_variant_klass = ApiSerializer::Serializer.build_variant(ApiSerializer::Schema, :new_test_variant, []) do
  #     attribute :name, String
  #   end
  #   assert serializer_variant_klass.ancestors.include? ApiSerializer::Serializer
  #   assert_equal :new_test_variant, serializer_variant_klass.variant_name
  #   assert_equal "api_schemas/NewTestVariantSerializer (ApiSerializer::Schema[:new_test_variant])", serializer_variant_klass.schema_name
  # end
  #
  # test "new_serializer_variant class method with mixin" do
  #   base_serializer_klass = ApiSerializer::Serializer.build_variant(ApiSerializer::Schema, :mixin, [])
  #   serializer_variant_klass = ApiSerializer::Serializer.build_variant(ApiSerializer::Schema, :mixin_test, [base_serializer_klass])
  #   assert_equal "api_schemas/MixinTestSerializer (ApiSerializer::Schema[:mixin_test]) composes templates/variants: [:mixin]", serializer_variant_klass.schema_name
  # end
  #
  # test "new_serializer_variant class method with different schema" do
  #   my_schema = Class.new(ApiSerializer::Schema) do
  #     def self.name
  #       "MySchema"
  #     end
  #   end
  #   serializer_variant_klass = ApiSerializer::Serializer.build_variant(my_schema, :custom_schema_test_variant)
  #   assert_equal "api_schemas/CustomSchemaTestVariantSerializer (MySchema[:custom_schema_test_variant])", serializer_variant_klass.schema_name
  # end
  #
  # test "new_serializer_variant class method with inherited" do
  #   new_serializer_klass = ApiSerializer::Serializer.build_variant(ApiSerializer::Schema, :base_variant)
  #   serializer_variant_klass = new_serializer_klass.build_variant(ApiSerializer::Schema, :inherits_test_variant)
  #   assert_equal "api_schemas/InheritsTestVariantSerializer (ApiSerializer::Schema[:inherits_test_variant]) inherits from template/variant: [:base_variant]", serializer_variant_klass.schema_name
  # end

  # --- queryable ---

  test "queryable: true makes attribute filterable and sortable" do
    builder = ApiSerializer::VariantBuilder.new(schema: ApiSerializer::Schema, name: :test_filterable)
    variant = builder.build do
      attribute :name, String, queryable: true
      attribute :age, Integer
    end

    assert variant.reflect_on(:name).filterable?
    refute variant.reflect_on(:age).filterable?
  end

  test "queryable: {sort: true, filter: false} makes attribute sortable only" do
    builder = ApiSerializer::VariantBuilder.new(schema: ApiSerializer::Schema, name: :test_sortable)
    variant = builder.build do
      attribute :name, String, queryable: {sort: true, filter: false}
      attribute :age, Integer
    end

    assert variant.reflect_on(:name).sortable?
    refute variant.reflect_on(:age).sortable?
  end

  test "virtual attribute cannot be filterable or sortable" do
    # virtual is never filterable/sortable by design — it computes from non-DB data
    builder = ApiSerializer::VariantBuilder.new(schema: ApiSerializer::Schema, name: :test_virtual_not_filterable)
    variant = builder.build do
      virtual :computed, String do |data|
        data[:something]
      end
    end

    refute variant.reflect_on(:computed).filterable?
    refute variant.reflect_on(:computed).sortable?
  end

  test "queryable: with explicit column uses that column in filtering_mapped_attributes" do
    builder = ApiSerializer::VariantBuilder.new(schema: ApiSerializer::Schema, name: :test_queryable_column)
    variant = builder.build do
      attribute :uom, String, from: "sell_unit", queryable: {column: "sell_uom"}
    end

    result = variant.filtering_mapped_attributes
    # Column-only mapping returns the column string directly (no transform needed)
    assert_equal "sell_uom", result[:uom]
  end

  test "queryable: with transform returns QueryableConfig in mapping" do
    transform = ->(api_value, _ctx) { api_value.upcase }
    builder = ApiSerializer::VariantBuilder.new(schema: ApiSerializer::Schema, name: :test_queryable_transform)
    variant = builder.build do
      attribute :uom, String, queryable: {column: "sell_uom", transform: transform}
    end

    result = variant.filtering_mapped_attributes
    assert_instance_of ApiSerializer::QueryableConfig, result[:uom]
    assert_equal "sell_uom", result[:uom].column
    assert_equal transform, result[:uom].transform
  end

  test "queryable: with allowed_values returns them in mapping" do
    builder = ApiSerializer::VariantBuilder.new(schema: ApiSerializer::Schema, name: :test_queryable_allowed)
    variant = builder.build do
      attribute :role, String, queryable: {allowed_values: %w[owner manager user]}
    end

    result = variant.filtering_mapped_attributes
    assert_instance_of ApiSerializer::QueryableConfig, result[:role]
    assert_equal %w[owner manager user], result[:role].allowed_values
  end

  test "queryable: without transform or allowed_values returns plain column mapping" do
    builder = ApiSerializer::VariantBuilder.new(schema: ApiSerializer::Schema, name: :test_queryable_plain)
    variant = builder.build do
      attribute :name, String, queryable: true
      attribute :email, String, from: "account.email", queryable: true
    end

    result = variant.filtering_mapped_attributes
    # Simple fields return String or nil, not QueryableConfig
    assert_nil result[:name]
    assert_equal "account.email", result[:email]
  end

  # --- filtering_mapped_attributes ---

  test "filtering_mapped_attributes returns only filterable attributes" do
    builder = ApiSerializer::VariantBuilder.new(schema: ApiSerializer::Schema, name: :test_filter_map)
    variant = builder.build do
      attribute :id, Integer, queryable: true
      attribute :name, String, queryable: true
      attribute :internal, String
    end

    result = variant.filtering_mapped_attributes
    assert_equal({id: nil, name: nil}, result)
  end

  test "filtering_mapped_attributes maps from_path as DB column" do
    builder = ApiSerializer::VariantBuilder.new(schema: ApiSerializer::Schema, name: :test_filter_from_path)
    variant = builder.build do
      attribute :email, String, from: "account.email", queryable: true
      attribute :phone, String, from: "user_profile.phone_number", queryable: true
      attribute :name, String  # not filterable
    end

    result = variant.filtering_mapped_attributes
    assert_equal({email: "account.email", phone: "user_profile.phone_number"}, result)
  end

  test "sorting_mapped_attributes returns only sortable attributes" do
    builder = ApiSerializer::VariantBuilder.new(schema: ApiSerializer::Schema, name: :test_sort_map)
    variant = builder.build do
      attribute :id, Integer, queryable: {sort: true, filter: false}
      attribute :name, String, queryable: {filter: true, sort: false}  # filterable only, not sortable
      attribute :created_at, Time, queryable: {sort: true, filter: false}
    end

    result = variant.sorting_mapped_attributes
    assert_equal({id: nil, created_at: nil}, result)
  end

  test "filtering_mapped_attributes with has_one recursively collects nested filterable attributes" do
    nested_schema = Class.new(ApiSerializer::Schema) do
      serializer :full do
        attribute :name, String, queryable: true
        attribute :email, String, from: "contact.email", queryable: true
        attribute :internal, String
      end
    end

    parent_schema = Class.new(ApiSerializer::Schema) do
      serializer :full do
        attribute :title, String, queryable: true
        has_one :author, nested_schema.serializer, queryable: true
      end
    end

    variant = parent_schema.fetch_variant(:serializer, false, :full)
    result = variant.filtering_mapped_attributes
    assert result.key?(:title)
    assert result.key?(:"author.name")
    assert result.key?(:"author.email")
    refute result.key?(:"author.internal")
    assert_match(/^author\./, result[:"author.email"])
  end

  test "filtering_mapped_attributes depth limit prevents infinite recursion" do
    # A schema that is nested 6 levels deep should hit the depth limit and return {}
    level6 = Class.new(ApiSerializer::Schema) do
      serializer :full do
        attribute :deep_field, String, queryable: true
      end
    end

    # Build chain: level1 -> level2 -> ... -> level6
    current = level6
    5.times do
      outer = current
      current = Class.new(ApiSerializer::Schema) do
        serializer :full do
          has_one :child, outer.serializer, queryable: true
        end
      end
    end

    # Should not raise (depth guard prevents infinite recursion)
    assert_nothing_raised do
      current.fetch_variant(:serializer, false, :full).filtering_mapped_attributes
    end
  end

  test "has_one not marked filterable is excluded from filtering_mapped_attributes" do
    nested_schema = Class.new(ApiSerializer::Schema) do
      serializer :full do
        attribute :name, String, queryable: true
      end
    end

    parent_schema = Class.new(ApiSerializer::Schema) do
      serializer :full do
        attribute :title, String, queryable: true
        has_one :author, nested_schema.serializer  # NOT marked filterable
      end
    end

    result = parent_schema.fetch_variant(:serializer, false, :full).filtering_mapped_attributes
    assert result.key?(:title)
    refute result.key?(:"author.name")
  end

  # --- has_one / has_many variant resolution ---

  test "has_one serializes using the parent variant when nested schema has it" do
    nested_schema = Class.new(ApiSerializer::Schema) do
      serializer :full do
        attribute :id, Integer
        attribute :name, String
      end
      serializer :minimal do
        attribute :id, Integer
      end
    end

    parent_schema = Class.new(ApiSerializer::Schema) do
      serializer :full do
        attribute :title, String
        has_one :child, nested_schema.serializer
      end
    end

    data = {title: "Parent", child: {id: 1, name: "Child"}}
    result = parent_schema.fetch_variant(:serializer, false, :full).serialize(data, {current_variant_name: :full})

    assert_equal "Parent", result.title
    assert_equal 1, result.child.id
    assert_equal "Child", result.child.name
  end

  test "has_one falls back to :nested when parent variant not on nested schema" do
    nested_schema = Class.new(ApiSerializer::Schema) do
      serializer :nested do
        attribute :id, Integer
        attribute :label, String
      end
      # No :full variant
    end

    parent_schema = Class.new(ApiSerializer::Schema) do
      serializer :full do
        attribute :title, String
        has_one :child, nested_schema.serializer
      end
    end

    data = {title: "Parent", child: {id: 7, label: "Nested Label"}}
    result = parent_schema.fetch_variant(:serializer, false, :full).serialize(data, {current_variant_name: :full})

    assert_equal "Parent", result.title
    assert_equal 7, result.child.id
    assert_equal "Nested Label", result.child.label
  end

  test "has_many serializes collection with variant fallback" do
    nested_schema = Class.new(ApiSerializer::Schema) do
      serializer :id_only do
        attribute :id, Integer
      end
      # No :full, :nested, or :minimal
    end

    parent_schema = Class.new(ApiSerializer::Schema) do
      serializer :full do
        attribute :title, String
        has_many :items, nested_schema.serializer
      end
    end

    data = {title: "Parent", items: [{id: 1}, {id: 2}]}
    result = parent_schema.fetch_variant(:serializer, false, :full).serialize(data, {current_variant_name: :full})

    assert_equal "Parent", result.title
    assert_equal 2, result.items.length
    assert_equal 1, result.items[0].id
  end

  # NOTE: When no suitable variant exists in the nested fallback chain, the association
  # transform rescues VariantNotFoundError and returns nil. However, DataTransformer
  # currently skips nil values (`hash[attr] = value unless value.nil?`), causing the
  # key to be missing from the struct constructor. This is a pre-existing limitation in
  # DataTransformer that should be addressed separately — the transformer needs to
  # distinguish between "value is nil" and "no value exists in the data".

  # --- context_with_variant injection ---

  test "SerializationContextWrapper injects current_variant_name into Hash context" do
    schema = Class.new(ApiSerializer::Schema) do
      serializer :minimal do
        attribute :id, Integer
      end
    end

    data_obj = {id: 42}
    wrapper = ApiSerializer::SerializationContextWrapper.new(data_obj, schema, {extra: "value"})
    result = wrapper.serialize(:minimal)

    assert_equal 42, result.id
  end

  test "SerializationContextWrapper does not override existing current_variant_name" do
    schema = Class.new(ApiSerializer::Schema) do
      serializer :minimal do
        attribute :id, Integer
      end
    end

    data_obj = {id: 42}
    wrapper = ApiSerializer::SerializationContextWrapper.new(data_obj, schema, {current_variant_name: :something_else})
    result = wrapper.serialize(:minimal)

    assert_equal 42, result.id
  end

  # --- has_one in deserializer context ---

  test "has_one works in deserializer variants (not just serializer)" do
    nested_schema = Class.new(ApiSerializer::Schema) do
      serializer :full do
        attribute :color, String
      end
      deserializer :create do
        attribute :color, String
      end
    end

    parent_schema = Class.new(ApiSerializer::Schema) do
      serializer :full do
        attribute :name, String
        has_one :widget, nested_schema.serializer
      end
      deserializer :create do
        attribute :name, String
        has_one :widget, nested_schema.deserializer
      end
    end

    # Serializer direction works (was already working)
    data = {name: "Parent", widget: {color: "red"}}
    result = parent_schema.fetch_variant(:serializer, false, :full).serialize(data, {current_variant_name: :full})
    assert_equal "Parent", result.name
    assert_equal "red", result.widget.color

    # Deserializer direction — this was broken before the fix
    input = {name: "Parent", widget: {color: "blue"}}
    result = parent_schema.fetch_variant(:deserializer, false, :create).deserialize(input, {current_variant_name: :create})
    assert_equal "Parent", result.name
    assert_equal "blue", result.widget.color
  end

  test "has_many works in deserializer variants" do
    nested_schema = Class.new(ApiSerializer::Schema) do
      deserializer :create do
        attribute :value, String
      end
    end

    parent_schema = Class.new(ApiSerializer::Schema) do
      deserializer :create do
        attribute :title, String
        has_many :items, nested_schema.deserializer
      end
    end

    input = {title: "List", items: [{value: "a"}, {value: "b"}]}
    result = parent_schema.fetch_variant(:deserializer, false, :create).deserialize(input, {current_variant_name: :create})
    assert_equal "List", result.title
    assert_equal 2, result.items.length
    assert_equal "a", result.items[0].value
    assert_equal "b", result.items[1].value
  end

  # --- has_one / has_many with _Nilable resolvers ---
  # _Nilable(Schema.serializer) means "this association may be nil". The
  # association_attribute / association_type code paths unwrap the inner
  # VariantResolver before storing it, while still using a NilableType in the
  # target struct so nil values are accepted at deserialize time.

  test "has_one accepts a _Nilable VariantResolver and serializes nil values" do
    nested_schema = Class.new(ApiSerializer::Schema) do
      serializer :full do
        attribute :name, String
      end
    end

    parent_schema = Class.new(ApiSerializer::Schema) do
      serializer :full do
        attribute :title, String
        has_one :child, _Nilable(nested_schema.serializer)
      end
    end

    # nil child → still serializes
    result = parent_schema.serializer_for(:full).transform({title: "P", child: nil})
    assert_equal "P", result.title
    assert_nil result.child

    # Present child → serializes through the unwrapped resolver
    result = parent_schema.serializer_for(:full).transform({title: "P", child: {name: "C"}})
    assert_equal "C", result.child.name
  end

  test "has_many accepts a _Nilable VariantResolver" do
    nested_schema = Class.new(ApiSerializer::Schema) do
      serializer :full do
        attribute :v, String
      end
    end

    parent_schema = Class.new(ApiSerializer::Schema) do
      serializer :full do
        attribute :title, String
        has_many :items, _Nilable(nested_schema.serializer)
      end
    end

    result = parent_schema.serializer_for(:full).transform({title: "P", items: [{v: "a"}]})
    assert_equal "a", result.items.first.v
  end

  test "association_type raises when given something other than a VariantResolver or _Nilable" do
    schema = Class.new(ApiSerializer::Schema)
    err = assert_raises(ApiSerializer::Errors::VariantDefinitionError) do
      schema.class_eval do
        serializer :full do
          has_one :child, "not-a-resolver"
        end
      end
      schema.serializer_for(:full) # force lazy build if needed
    end
    assert_match(/serializer_variant must be a VariantResolver/, err.message)
  end

  # --- VariantNotFoundError fallback in the has_one transform proc ---
  # When the nested resolver can't find any suitable variant for the requested
  # variant_name (and exhausts its fallbacks), the rescue block returns nil so
  # the parent serializes without the association rather than raising.

  test "has_one association silently omits values when nested variant cannot be resolved" do
    nested_schema = Class.new(ApiSerializer::Schema) do
      serializer :something_else do  # NB: not :full and no fallback
        attribute :name, String
      end
    end

    parent_schema = Class.new(ApiSerializer::Schema) do
      serializer :full do
        attribute :title, String
        # Use _Nilable so the parent struct accepts nil when the nested resolver bails.
        has_one :child, _Nilable(nested_schema.serializer)
      end
    end

    # The nested schema has no :full / :nested fallback for :full, so the
    # convert_by proc rescues VariantNotFoundError and yields nil for child.
    result = parent_schema.serializer_for(:full).transform({title: "P", child: {name: "C"}})
    assert_equal "P", result.title
    assert_nil result.child
  end

  # --- sorting_mapped_attributes recursion through associations ---

  test "sorting_mapped_attributes with has_one recursively collects nested sortable attributes" do
    nested_schema = Class.new(ApiSerializer::Schema) do
      serializer :full do
        attribute :name, String, queryable: {sort: true, filter: false}
      end
    end

    parent_schema = Class.new(ApiSerializer::Schema) do
      serializer :full do
        attribute :title, String, queryable: {sort: true, filter: false}
        has_one :author, nested_schema.serializer, queryable: {sort: true, filter: false}
      end
    end

    variant = parent_schema.fetch_variant(:serializer, false, :full)
    result = variant.sorting_mapped_attributes
    assert result.key?(:title)
    assert result.key?(:"author.name")
  end

  # The base Serialization class defines stub schema_name / composed_with that
  # raise NoMethodError — they are overridden by the variant builder when a
  # concrete serialization subclass is created. Calling them on the base class
  # should still raise.
  test "schema_name raises NoMethodError on the base Serialization class" do
    assert_raises(NoMethodError) { ApiSerializer::Serialization.schema_name }
  end

  test "composed_with raises NoMethodError on the base Serialization class" do
    assert_raises(NoMethodError) { ApiSerializer::Serialization.composed_with }
  end
end
