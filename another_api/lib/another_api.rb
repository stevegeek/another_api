# frozen_string_literal: true

require "rails"
require "action_policy"
require "dry/monads"
require "api_serializer"
require "api_query_language"
require "api_query_language/active_record"

require_relative "another_api/version"
require_relative "another_api/configuration"

module AnotherApi
end

# Errors and value classes.
require_relative "another_api/bad_request_error"
require_relative "another_api/forbidden_error"
require_relative "another_api/not_acceptable_error"
require_relative "another_api/not_found_error"
require_relative "another_api/unprocessable_error"
require_relative "another_api/operation_failure"

# Scopes / scope registry.
require_relative "another_api/scope"
require_relative "another_api/scopes"

# Authentication / token handling.
require_relative "another_api/token_generation"
require_relative "another_api/api_token_contract"

# Policies.
require_relative "another_api/api_token_scoped_policy"
require_relative "another_api/api_token_ownership_policy"

# Controller concerns. Engine must be loaded last so it can reference the
# constants above when Rails runs the after_initialize validation.
require_relative "another_api/param_sanitizer"
require_relative "another_api/authentication"
require_relative "another_api/error_handling"
require_relative "another_api/response_handler"
require_relative "another_api/schema_configurable"
require_relative "another_api/paginated"
require_relative "another_api/response_has_metadata"
require_relative "another_api/filtered_and_sorted"
require_relative "another_api/param_deserializer"
require_relative "another_api/serializes"
require_relative "another_api/base_controller"

require_relative "another_api/engine"
