# frozen_string_literal: true

require "test_helper"

class AnotherApi::ConfigurationTest < Minitest::Test
  def setup
    @prev = AnotherApi.instance_variable_get(:@configuration)
    AnotherApi.reset_configuration!
  end

  def teardown
    AnotherApi.instance_variable_set(:@configuration, @prev)
  end

  def test_defaults
    c = AnotherApi.configuration
    assert_equal "ApiToken", c.token_model
    assert_equal "aa", c.token_prefix
    assert_equal "api.v2.", c.scope_prefix
    assert_equal 20, c.default_page_size
    assert_equal 200, c.max_page_size
  end

  def test_configure_yields_the_singleton_configuration
    AnotherApi.configure do |c|
      c.token_model = "MyToken"
      c.default_page_size = 42
    end
    assert_equal "MyToken", AnotherApi.configuration.token_model
    assert_equal 42, AnotherApi.configuration.default_page_size
  end

  def test_error_status_map_defaults
    map = AnotherApi.configuration.error_status_map
    assert_equal :bad_request, map[:validation_error]
    assert_equal :unprocessable_entity, map[:unprocessable_content]
    assert_equal :forbidden, map[:forbidden]
    assert_equal :unauthorized, map[:unauthorized]
  end

  def test_rescue_from_appends_to_the_registry
    AnotherApi.configuration.rescue_from "MyApp::OopsError", as: :bad_request
    assert_equal [{exception: "MyApp::OopsError", error_type: :bad_request}],
      AnotherApi.configuration.rescue_registry
  end

  def test_reset_configuration_replaces_the_singleton
    original = AnotherApi.configuration
    AnotherApi.reset_configuration!
    refute_same original, AnotherApi.configuration
  end

  def test_validate_raises_when_token_secret_is_nil
    AnotherApi.reset_configuration!
    AnotherApi.configuration.token_model = "ApiToken"
    err = assert_raises(AnotherApi::ConfigurationError) { AnotherApi.configuration.validate! }
    assert_match(/token_secret/, err.message)
  end

  def test_validate_raises_when_token_secret_is_empty_string
    AnotherApi.reset_configuration!
    AnotherApi.configuration.token_secret = ""
    assert_raises(AnotherApi::ConfigurationError) { AnotherApi.configuration.validate! }
  end

  def test_validate_raises_when_token_model_is_nil
    AnotherApi.reset_configuration!
    AnotherApi.configuration.token_secret = "s3cret"
    AnotherApi.configuration.token_model = nil
    err = assert_raises(AnotherApi::ConfigurationError) { AnotherApi.configuration.validate! }
    assert_match(/token_model/, err.message)
  end

  def test_validate_passes_when_required_values_are_set
    AnotherApi.reset_configuration!
    AnotherApi.configuration.token_secret = "s3cret"
    AnotherApi.configure { |c| c.token_model = "ApiToken" }
    assert_nil AnotherApi.configuration.validate!
  end
end
