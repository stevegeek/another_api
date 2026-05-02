# frozen_string_literal: true

require "test_helper"

class AnotherApi::ParamDeserializerTest < Minitest::Test
  class PostSchema < ApiSerializer::Schema
    deserializer :create do
      attribute :title, String
      attribute :body, String
      # Probe: echoes data[:owner_bearer_id] so the test can tell whether
      # the deserializer leaked request input into virtual-attr input.
      virtual :owner_bearer_id, _Nilable(Integer) do |data|
        data.is_a?(Hash) ? data[:owner_bearer_id] : nil
      end
      attribute :slug, _Nilable(String), from: "meta_slug"
    end
  end

  class Host < ::ActionController::API
    include AnotherApi::ParamDeserializer

    attr_accessor :params

    public :deserialize_params, :schema_input_keys
  end

  def setup
    @host = Host.new
  end

  def test_schema_input_keys_excludes_virtual_attributes
    tds = PostSchema.deserializer_for(:create).target_data_structure
    keys = @host.schema_input_keys(tds)
    assert_includes keys, :title
    assert_includes keys, :body
    refute_includes keys, :owner_bearer_id, "virtual attributes must not be accepted from input"
  end

  def test_schema_input_keys_honours_explicit_from_remap
    tds = PostSchema.deserializer_for(:create).target_data_structure
    keys = @host.schema_input_keys(tds)
    assert_includes keys, :meta_slug
    refute_includes keys, :slug
  end

  def test_deserialize_params_drops_keys_outside_the_schema
    @host.params = ActionController::Parameters.new(
      "title" => "Hello",
      "body" => "World",
      "owner_bearer_id" => 999,
      "admin_override" => true,
      "controller" => "posts",
      "action" => "create",
      "meta_slug" => "hello-world"
    )

    result = @host.deserialize_params(PostSchema, :create)

    assert_equal "Hello", result.title
    assert_equal "World", result.body
    assert_equal "hello-world", result.slug
    assert_nil result.owner_bearer_id, "virtual attribute was populated from request input — mass-assignment regression"
  end
end
