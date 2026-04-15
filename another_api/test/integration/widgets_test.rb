# frozen_string_literal: true

require "test_helper"

# End-to-end smoke test that exercises the engine through the dummy Rails app:
# auth, error handling, policy/scope checks, and the Dry::Monads response
# pipeline.
class WidgetsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    Test::WidgetsController::STORE.clear
    ApiToken.delete_all
    Bearer.delete_all
    @bearer = Bearer.create!(name: "bearer-1")
    @token = "dt_test_widget_token_value_aaa"
    ApiToken.create_with_raw!(@token,
      bearer: @bearer,
      scopes: %w[api.test.widgets.list api.test.widgets.show api.test.widgets.create])
  end

  def auth_headers(extra = {})
    {"Authorization" => "Bearer #{@token}", "Accept" => "application/json"}.merge(extra)
  end

  test "401 when no Authorization header is sent" do
    get "/api/test/widgets", headers: {"Accept" => "application/json"}
    assert_response :unauthorized
    body = JSON.parse(response.body, symbolize_names: true)
    assert_equal "unauthorized", body[:error_type]
  end

  test "401 when a bogus bearer token is sent" do
    get "/api/test/widgets", headers: {"Accept" => "application/json", "Authorization" => "Bearer not-a-real-token"}
    assert_response :unauthorized
  end

  test "200 with empty list when authenticated and authorized" do
    get "/api/test/widgets", headers: auth_headers
    assert_response :ok
    body = JSON.parse(response.body, symbolize_names: true)
    assert body[:success]
    assert_equal [], body[:data]
  end

  test "201 + body when creating a widget" do
    post "/api/test/widgets", headers: auth_headers, params: {name: "Sprocket"}
    assert_response :created
    body = JSON.parse(response.body, symbolize_names: true)
    assert body[:success]
    assert_equal "Sprocket", body[:data][:name]
  end

  test "400 bad_request when create payload is invalid" do
    post "/api/test/widgets", headers: auth_headers, params: {}
    assert_response :bad_request
    body = JSON.parse(response.body, symbolize_names: true)
    assert_equal "bad_request", body[:error_type]
    assert_match(/name is required/, body[:error_message])
  end

  test "404 not_found for unknown id" do
    get "/api/test/widgets/999", headers: auth_headers
    assert_response :not_found
    body = JSON.parse(response.body, symbolize_names: true)
    assert_equal "not_found", body[:error_type]
  end

  test "403 forbidden when the token has no applicable scopes" do
    no_scope_token = "dt_no_scope_token_zzz_yyy"
    ApiToken.create_with_raw!(no_scope_token, bearer: @bearer, scopes: [])
    get "/api/test/widgets", headers: {"Authorization" => "Bearer #{no_scope_token}", "Accept" => "application/json"}
    assert_response :forbidden
    body = JSON.parse(response.body, symbolize_names: true)
    assert_equal "forbidden", body[:error_type]
  end

  test "403 forbidden when token is revoked" do
    revoked_token = "dt_revoked_token_aaa_bbb"
    ApiToken.create_with_raw!(revoked_token,
      bearer: @bearer,
      scopes: %w[api.test.widgets.list],
      revoked_at: 1.minute.ago)
    get "/api/test/widgets", headers: {"Authorization" => "Bearer #{revoked_token}", "Accept" => "application/json"}
    # Revoked tokens fail authentication itself (active? returns false).
    assert_response :unauthorized
  end

  # ResponseHandler arms — each `flavour` exercises a different Success/Failure
  # pattern in api_respond_to_json.

  test "Success(String) renders a 200 with success+message" do
    post "/api/test/widgets", headers: auth_headers, params: {flavour: "string_message"}
    assert_response :ok
    body = JSON.parse(response.body, symbolize_names: true)
    assert body[:success]
    assert_equal "a plain string success message", body[:message]
  end

  test "Success() with no args renders 204 No Content" do
    post "/api/test/widgets", headers: auth_headers, params: {flavour: "no_content"}
    assert_response :no_content
  end

  test "Success(Hash) renders 200 with the hash as data" do
    post "/api/test/widgets", headers: auth_headers, params: {flavour: "raw_data"}
    assert_response :ok
    body = JSON.parse(response.body, symbolize_names: true)
    assert_equal({id: 1, name: "raw"}, body[:data])
  end

  test "Failure(OperationFailure) renders 400 with destructured details" do
    post "/api/test/widgets", headers: auth_headers, params: {flavour: "operation_failure"}
    assert_response :bad_request
    body = JSON.parse(response.body, symbolize_names: true)
    assert_equal "invalid_field", body[:error_type]
    assert_equal "name too short", body[:error_message]
    assert_equal ["name"], body[:details]
  end

  test "Failure[type, message, *details] renders the details key" do
    post "/api/test/widgets", headers: auth_headers, params: {flavour: "bad_request", name: "anything"}
    assert_response :bad_request
    body = JSON.parse(response.body, symbolize_names: true)
    assert_equal ["name"], body[:details]
  end

  # ErrorHandling rescues — each raise here is caught by a rescue_from in the
  # gem and rendered as an appropriate JSON error.

  test "raised NotAcceptableError → 406" do
    post "/api/test/widgets", headers: auth_headers, params: {flavour: "not_acceptable"}
    assert_response :not_acceptable
    body = JSON.parse(response.body, symbolize_names: true)
    assert_equal "not_acceptable", body[:error_type]
  end

  test "raised UnprocessableError → 422" do
    post "/api/test/widgets", headers: auth_headers, params: {flavour: "unprocessable"}
    assert_response :unprocessable_entity
    body = JSON.parse(response.body, symbolize_names: true)
    assert_equal "unprocessable_entity", body[:error_type]
  end

  # Failure[type, ::ActiveRecord::Base] arm of the ResponseHandler.
  test "Failure[:validation_error, model] renders a 400 with the model's errors" do
    post "/api/test/widgets", headers: auth_headers, params: {flavour: "ar_validation_failure"}
    assert_response :bad_request
    body = JSON.parse(response.body, symbolize_names: true)
    assert_equal "validation_error", body[:error_type]
    assert_match(/Validation failed/, body[:error_message])
    assert body[:errors].is_a?(Hash)
  end

  # The three ActiveRecord/Model/ParameterMissing rescues inside api_respond_to_json.
  test "raised ActiveRecord::RecordInvalid renders 400 validation_error" do
    post "/api/test/widgets", headers: auth_headers, params: {flavour: "raised_record_invalid"}
    assert_response :bad_request
    body = JSON.parse(response.body, symbolize_names: true)
    assert_equal "validation_error", body[:error_type]
  end

  test "raised ActiveModel::ValidationError renders 400 validation_error" do
    post "/api/test/widgets", headers: auth_headers, params: {flavour: "raised_validation_error"}
    assert_response :bad_request
    body = JSON.parse(response.body, symbolize_names: true)
    assert_equal "validation_error", body[:error_type]
  end

  test "raised ActionController::ParameterMissing renders 400 missing_parameter" do
    post "/api/test/widgets", headers: auth_headers, params: {flavour: "raised_parameter_missing"}
    assert_response :bad_request
    body = JSON.parse(response.body, symbolize_names: true)
    assert_equal "missing_parameter", body[:error_type]
  end

  # Failure(:symbol) arms — these get re-raised as gem exceptions and caught
  # by the ErrorHandling concern.
  test "Failure(:forbidden) → 403" do
    post "/api/test/widgets", headers: auth_headers, params: {flavour: "failure_forbidden_symbol"}
    assert_response :forbidden
  end

  test "Failure(:not_permitted) → 403" do
    post "/api/test/widgets", headers: auth_headers, params: {flavour: "failure_not_permitted_symbol"}
    assert_response :forbidden
  end

  test "Failure(:bad_request) → 400" do
    post "/api/test/widgets", headers: auth_headers, params: {flavour: "failure_bad_request_symbol"}
    assert_response :bad_request
  end

  test "Failure(unknown_symbol) → defaults to bad_request via error_status_for fallback" do
    post "/api/test/widgets", headers: auth_headers, params: {flavour: "failure_bogus_symbol"}
    assert_response :bad_request
  end

  # raise_* helper methods on the controller.
  test "raise_forbidden helper renders 403" do
    post "/api/test/widgets", headers: auth_headers, params: {flavour: "raise_forbidden_helper"}
    assert_response :forbidden
  end

  test "raise_bad_request helper renders 400" do
    post "/api/test/widgets", headers: auth_headers, params: {flavour: "raise_bad_request_helper"}
    assert_response :bad_request
  end

  test "raise_not_found helper renders 404" do
    post "/api/test/widgets", headers: auth_headers, params: {flavour: "raise_not_found_helper"}
    assert_response :not_found
  end
end
