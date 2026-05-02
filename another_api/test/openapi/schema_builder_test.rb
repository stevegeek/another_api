# frozen_string_literal: true

require "test_helper"
require "another_api/openapi"

class AnotherApi::OpenAPI::SchemaBuilderTest < Minitest::Test
  def setup
    @prev = AnotherApi::OpenAPI.instance_variable_get(:@configuration)
    AnotherApi::OpenAPI.reset_configuration!
    AnotherApi::OpenAPI.configuration.default_variant_name = :default
  end

  def teardown
    AnotherApi::OpenAPI.instance_variable_set(:@configuration, @prev)
  end

  def test_builds_schema_for_serializer_variant
    schemas = AnotherApi::OpenAPI::SchemaBuilder.new(
      {"Post" => CoreSchemas::V2::Post}
    ).build_all

    assert schemas.key?("PostFull"), "Expected PostFull schema; got #{schemas.keys.inspect}"
    post_schema = schemas["PostFull"]

    assert_equal "object", post_schema[:type]
    assert post_schema[:properties].key?(:id)
    assert post_schema[:properties].key?(:title)
    assert post_schema[:properties].key?(:body)
  end

  def test_required_excludes_nilable_attributes
    schemas = AnotherApi::OpenAPI::SchemaBuilder.new(
      {"Post" => CoreSchemas::V2::Post}
    ).build_all

    post = schemas["PostFull"]
    assert post[:required].include?("id")
    assert post[:required].include?("title")
    refute post[:required].include?("body"), "body is _Nilable so should not be required"
    refute post[:required].include?("status"), "status is _Nilable so should not be required"
  end

  def test_allowed_values_are_emitted_as_enum
    schemas = AnotherApi::OpenAPI::SchemaBuilder.new(
      {"Post" => CoreSchemas::V2::Post}
    ).build_all

    status_prop = schemas["PostFull"][:properties][:status]
    assert_equal %w[draft published], status_prop[:enum]
  end

  def test_builds_deserializer_input_schema
    schemas = AnotherApi::OpenAPI::SchemaBuilder.new(
      {"Post" => CoreSchemas::V2::Post}
    ).build_all

    assert schemas.key?("PostCreateInput"),
      "Expected PostCreateInput schema; got #{schemas.keys.inspect}"
    input_schema = schemas["PostCreateInput"]
    assert input_schema[:properties].key?(:title)
  end

  def test_includes_pagination_metadata_and_filter_expression_common_schemas
    schemas = AnotherApi::OpenAPI::SchemaBuilder.new({}).build_all
    assert schemas.key?("PaginationMetadata")
    assert schemas.key?("FilterExpression")
  end

  # ------------------------------------------------------------------
  # Association handling
  # ------------------------------------------------------------------

  module Fixture
    class Author < ApiSerializer::Schema
      serializer :default do
        attribute :id, Integer
        attribute :name, String
      end
    end

    class Comment < ApiSerializer::Schema
      serializer :default do
        attribute :id, Integer
        attribute :body, String
      end
    end

    class Article < ApiSerializer::Schema
      serializer :default do
        attribute :id, Integer
        attribute :title, String
        has_one :author, Author.serializer
        has_one :nilable_author, _Nilable(Author.serializer)
        has_many :comments, Comment.serializer
      end
    end

    # Standalone schema whose nested target isn't in the registry — used to
    # exercise SchemaBuilder's "infer fails -> {type: 'object'}" fallback.
    class UnknownTarget < ApiSerializer::Schema
      serializer :default do
        attribute :id, Integer
      end
    end

    class HasUnknownAssociation < ApiSerializer::Schema
      serializer :default do
        attribute :id, Integer
        has_one :stranger, UnknownTarget.serializer
      end
    end
  end

  def registry
    {
      "Article" => Fixture::Article,
      "Author" => Fixture::Author,
      "Comment" => Fixture::Comment
    }
  end

  def test_has_one_emits_ref_to_nested_schema
    schemas = AnotherApi::OpenAPI::SchemaBuilder.new(registry).build_all
    author_prop = schemas["ArticleFull"][:properties][:author]

    assert_equal "#/components/schemas/AuthorFull", author_prop["$ref"]
  end

  def test_has_many_emits_array_with_items_ref
    schemas = AnotherApi::OpenAPI::SchemaBuilder.new(registry).build_all
    comments_prop = schemas["ArticleFull"][:properties][:comments]

    assert_equal "array", comments_prop[:type]
    assert_equal "#/components/schemas/CommentFull", comments_prop[:items]["$ref"]
  end

  def test_nilable_has_one_emits_one_of_with_null
    schemas = AnotherApi::OpenAPI::SchemaBuilder.new(registry).build_all
    nilable_prop = schemas["ArticleFull"][:properties][:nilable_author]

    assert nilable_prop[:oneOf], "Expected oneOf for nilable association"
    refs = nilable_prop[:oneOf].map { |o| o["$ref"] || o }
    assert_includes refs, "#/components/schemas/AuthorFull"
    assert(nilable_prop[:oneOf].any? { |o| o[:type] == "null" })
  end

  def test_nilable_has_one_is_not_required
    schemas = AnotherApi::OpenAPI::SchemaBuilder.new(registry).build_all
    refute schemas["ArticleFull"][:required]&.include?("nilable_author")
  end

  def test_association_to_unknown_schema_falls_back_to_object
    schemas = AnotherApi::OpenAPI::SchemaBuilder.new(
      {"HasUnknownAssociation" => Fixture::HasUnknownAssociation}
    ).build_all

    stranger = schemas["HasUnknownAssociationFull"][:properties][:stranger]
    assert_equal "object", stranger[:type], "Expected object fallback when target schema isn't in the registry"
  end

  # ------------------------------------------------------------------
  # Variant-name suffix conventions
  # ------------------------------------------------------------------

  module VariantNameFixture
    class Thing < ApiSerializer::Schema
      serializer :default do
        attribute :id, Integer
        attribute :name, String
      end

      serializer :id_only do
        attribute :id, Integer
      end

      serializer :minimal do
        attribute :id, Integer
        attribute :name, String
      end
    end
  end

  def test_id_only_variant_is_named_with_id_only_suffix
    schemas = AnotherApi::OpenAPI::SchemaBuilder.new(
      {"Thing" => VariantNameFixture::Thing}
    ).build_all

    assert schemas.key?("ThingIdOnly"), "Expected ThingIdOnly schema; got #{schemas.keys.inspect}"
  end

  def test_arbitrary_variant_names_are_camelized
    schemas = AnotherApi::OpenAPI::SchemaBuilder.new(
      {"Thing" => VariantNameFixture::Thing}
    ).build_all

    assert schemas.key?("ThingMinimal"), "Expected ThingMinimal schema; got #{schemas.keys.inspect}"
  end
end
