# frozen_string_literal: true

# Opt-in OpenAPI 3.1 spec generator for another_api applications.
#
#   require "another_api/openapi"
#
#   AnotherApi::OpenAPI.configure do |c|
#     c.title = "My API"
#     c.version = "1.0"
#     c.path_prefix = "/api/v1"
#     c.controllers_glob = "app/controllers/api/v1/**/*_controller.rb"
#     c.schema_namespace_prefix = "MyApp::Schemas::V1::"
#   end
#
# Then in each controller:
#
#   include AnotherApi::OpenAPI::EndpointMetadata
#   api_resource "Users", schema: -> { MyApp::Schemas::V1::User }
#   api_action :index, summary: "List users"
#
# Generate the spec:
#
#   AnotherApi::OpenAPI::Generator.generate

require "another_api"

module AnotherApi
  module OpenAPI
  end
end

require_relative "openapi/common_schemas"
require_relative "openapi/configuration"
require_relative "openapi/type_mapper"
require_relative "openapi/schema_builder"
require_relative "openapi/endpoint_registry"
require_relative "openapi/endpoint_metadata"
require_relative "openapi/path_builder"
require_relative "openapi/generator"
require_relative "openapi/spec_renderer"
