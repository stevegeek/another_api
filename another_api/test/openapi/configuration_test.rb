# frozen_string_literal: true

require "test_helper"
require "another_api/openapi"

class AnotherApi::OpenAPI::ConfigurationTest < Minitest::Test
  def setup
    @prev = AnotherApi::OpenAPI.instance_variable_get(:@configuration)
    AnotherApi::OpenAPI.reset_configuration!
  end

  def teardown
    AnotherApi::OpenAPI.instance_variable_set(:@configuration, @prev)
  end

  def test_defaults
    c = AnotherApi::OpenAPI.configuration
    assert_equal "API", c.title
    assert_equal "1.0.0", c.version
    assert_equal "", c.path_prefix
    assert_equal "", c.schema_namespace_prefix
    assert_equal :full, c.default_variant_name
    assert_equal [:minimal], c.additional_discovery_variants
    assert c.eager_load_controllers
    assert_equal ["app/controllers"], c.watched_dirs
  end

  def test_default_concern_map_contains_another_api_concerns
    c = AnotherApi::OpenAPI.configuration
    assert_equal :paginated, c.concern_map["AnotherApi::Paginated"]
    assert_equal :filtered_and_sorted, c.concern_map["AnotherApi::FilteredAndSorted"]
    assert_equal :schema_configurable, c.concern_map["AnotherApi::SchemaConfigurable"]
  end

  def test_register_concern_extends_the_map
    AnotherApi::OpenAPI.configuration.register_concern("MyApp::Filterable", :my_filter)
    assert_equal :my_filter, AnotherApi::OpenAPI.configuration.concern_map["MyApp::Filterable"]
    # Existing entries are preserved
    assert_equal :paginated, AnotherApi::OpenAPI.configuration.concern_map["AnotherApi::Paginated"]
  end

  def test_configure_yields_the_singleton
    AnotherApi::OpenAPI.configure do |c|
      c.title = "My API"
      c.version = "2.0"
      c.schema_namespace_prefix = "MyApp::Schemas::V2::"
    end

    assert_equal "My API", AnotherApi::OpenAPI.configuration.title
    assert_equal "2.0", AnotherApi::OpenAPI.configuration.version
    assert_equal "MyApp::Schemas::V2::", AnotherApi::OpenAPI.configuration.schema_namespace_prefix
  end

  def test_reset_configuration_replaces_the_singleton
    original = AnotherApi::OpenAPI.configuration
    AnotherApi::OpenAPI.reset_configuration!
    refute_same original, AnotherApi::OpenAPI.configuration
  end
end
