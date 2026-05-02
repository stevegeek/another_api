# frozen_string_literal: true

require "test_helper"
require "another_api/openapi"

class AnotherApi::OpenAPI::EndpointRegistryTest < Minitest::Test
  def setup
    @prev = AnotherApi::OpenAPI.instance_variable_get(:@configuration)
    AnotherApi::OpenAPI.reset_configuration!
  end

  def teardown
    AnotherApi::OpenAPI.instance_variable_set(:@configuration, @prev)
    AnotherApi::OpenAPI::EndpointRegistry.clear!
  end

  def test_short_name_demodulizes_when_no_prefix_configured
    name = AnotherApi::OpenAPI::EndpointRegistry.schema_short_name(CoreSchemas::V2::Post)
    assert_equal "Post", name
  end

  def test_short_name_strips_configured_prefix_and_collapses_subnamespaces
    AnotherApi::OpenAPI.configuration.schema_namespace_prefix = "CoreSchemas::V2::"
    name = AnotherApi::OpenAPI::EndpointRegistry.schema_short_name(CoreSchemas::V2::Post)
    assert_equal "Post", name

    nested = Class.new(ApiSerializer::Schema)
    Object.const_set(:TestNamespaceForRegistry, Module.new)
    TestNamespaceForRegistry.const_set(:Cart, nested)
    # Define a class under the configured prefix path so the name actually
    # has the prefix to strip.
    CoreSchemas::V2.const_set(:Seller, Module.new) unless defined?(CoreSchemas::V2::Seller)
    CoreSchemas::V2::Seller.const_set(:Cart, Class.new(ApiSerializer::Schema)) unless defined?(CoreSchemas::V2::Seller::Cart)

    assert_equal "SellerCart",
      AnotherApi::OpenAPI::EndpointRegistry.schema_short_name(CoreSchemas::V2::Seller::Cart)
  ensure
    Object.send(:remove_const, :TestNamespaceForRegistry) if defined?(TestNamespaceForRegistry)
  end

  def test_short_name_falls_back_to_demodulize_when_prefix_does_not_match
    AnotherApi::OpenAPI.configuration.schema_namespace_prefix = "Other::Prefix::"
    name = AnotherApi::OpenAPI::EndpointRegistry.schema_short_name(CoreSchemas::V2::Post)
    assert_equal "Post", name
  end

  def test_register_and_clear
    entry = AnotherApi::OpenAPI::EndpointRegistry::Entry.new(
      controller_class: Test::PostsController,
      action: :index,
      summary: "List posts",
      tags: ["Posts"],
      schema_lambda: -> { CoreSchemas::V2::Post },
      description: nil,
      custom_path: nil,
      custom_verb: nil,
      custom_operation_id: nil,
      custom_query_params: nil
    )
    AnotherApi::OpenAPI::EndpointRegistry.register(entry)
    assert_equal 1, AnotherApi::OpenAPI::EndpointRegistry.all.size
    AnotherApi::OpenAPI::EndpointRegistry.clear!
    assert_equal 0, AnotherApi::OpenAPI::EndpointRegistry.all.size
  end

  def test_verb_for_action_maps_crud_actions
    registry = AnotherApi::OpenAPI::EndpointRegistry
    assert_equal "get", registry.send(:verb_for_action, "index")
    assert_equal "get", registry.send(:verb_for_action, "show")
    assert_equal "post", registry.send(:verb_for_action, "create")
    assert_equal "patch", registry.send(:verb_for_action, "update")
    assert_equal "delete", registry.send(:verb_for_action, "destroy")
  end

  def test_verb_for_action_falls_back_to_get_for_unknown_actions
    assert_equal "get", AnotherApi::OpenAPI::EndpointRegistry.send(:verb_for_action, "search")
  end

  def test_resolved_endpoints_strips_configured_path_prefix
    AnotherApi::OpenAPI.configuration.path_prefix = "/api/test"
    entry = AnotherApi::OpenAPI::EndpointRegistry::Entry.new(
      controller_class: Test::PostsController,
      action: :index,
      summary: "List posts",
      tags: ["Posts"],
      schema_lambda: -> { CoreSchemas::V2::Post },
      description: nil,
      custom_path: nil,
      custom_verb: nil,
      custom_operation_id: nil,
      custom_query_params: nil
    )
    AnotherApi::OpenAPI::EndpointRegistry.register(entry)

    resolved = AnotherApi::OpenAPI::EndpointRegistry.resolved_endpoints
    assert_equal 1, resolved.size
    assert_equal "/posts", resolved.first[:path]
    assert_equal "get", resolved.first[:verb]
    assert_equal "PostFull", resolved.first[:schema_ref]
  end
end
