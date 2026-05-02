# frozen_string_literal: true

module AnotherApi
  module OpenAPI
    # Include this concern in API controllers to declare endpoint metadata
    # that the OpenAPI generator picks up automatically.
    #
    #   class UsersController < AnotherApi::BaseController
    #     include AnotherApi::OpenAPI::EndpointMetadata
    #
    #     api_resource "Account - Users",
    #       schema: -> { MyApp::Schemas::V1::User },
    #       description: "Manage users for your organisation"
    #
    #     api_action :index, summary: "List users"
    #     api_action :show,  summary: "Get a single user"
    #   end
    #
    module EndpointMetadata
      extend ActiveSupport::Concern

      class_methods do
        # Declare resource-level metadata shared by all actions in this controller.
        #
        # @param tag [String] the OpenAPI tag (shown as a group heading)
        # @param schema [Proc, nil] a lambda returning the ApiSerializer::Schema class
        # @param description [String, nil] resource-level description
        def api_resource(tag, schema: nil, description: nil)
          @_api_resource_tag = tag
          @_api_resource_schema = schema
          @_api_resource_description = description
        end

        # Declare a single endpoint action.
        #
        # @param action [Symbol] the Rails action name (:index, :show, etc.)
        # @param summary [String] short summary for the OpenAPI operation
        # @param description [String, nil] longer description for the OpenAPI operation (overrides resource-level)
        # @param path [String, nil] override the auto-detected route path
        # @param verb [String, nil] override the auto-detected HTTP verb
        # @param operation_id [String, nil] override the auto-generated operation ID
        # @param schema [Proc, nil] override the resource-level schema for this action
        # @param tags [Array<String>, nil] override the resource-level tag
        # @param query_params [Array<Hash>, nil] additional query parameters
        #   Each hash: {name:, type:, required:, description:, format:}
        def api_action(action, summary:, description: nil, path: nil, verb: nil, operation_id: nil, schema: nil, tags: nil, query_params: nil)
          entry = AnotherApi::OpenAPI::EndpointRegistry::Entry.new(
            controller_class: self,
            action: action,
            summary: summary,
            tags: tags || Array(@_api_resource_tag),
            schema_lambda: schema || @_api_resource_schema,
            description: description || @_api_resource_description,
            custom_path: path,
            custom_verb: verb,
            custom_operation_id: operation_id,
            custom_query_params: query_params
          )

          AnotherApi::OpenAPI::EndpointRegistry.register(entry)
        end
      end
    end
  end
end
