# frozen_string_literal: true

require "test_helper"
require "another_api/openapi"

class AnotherApi::OpenAPI::CommonSchemasTest < Minitest::Test
  def test_default_parameters_include_pagination_filter_sort
    params = AnotherApi::OpenAPI::CommonSchemas.default_parameters
    %i[page page_size variant filter sort deleted active].each do |key|
      assert params.key?(key), "Missing parameter #{key}"
      assert_equal "query", params[key][:in]
    end
  end

  def test_default_pagination_metadata_describes_envelope_fields
    schema = AnotherApi::OpenAPI::CommonSchemas.default_pagination_metadata
    assert_equal "object", schema[:type]
    %i[total_count total_pages has_more request_id].each do |field|
      assert schema[:properties].key?(field), "Missing property #{field}"
    end
  end

  def test_default_error_response_uses_application_json
    err = AnotherApi::OpenAPI::CommonSchemas.default_error_response
    assert err.key?("application/json")
    schema = err["application/json"][:schema]
    assert_equal [false], schema[:properties][:success][:enum]
    assert_equal "string", schema[:properties][:error_type][:type]
  end

  def test_default_security_schemes_provide_bearer_auth
    schemes = AnotherApi::OpenAPI::CommonSchemas.default_security_schemes
    assert_equal "http", schemes[:bearerAuth][:type]
    assert_equal "bearer", schemes[:bearerAuth][:scheme]
  end
end
