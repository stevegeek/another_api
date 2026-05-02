# frozen_string_literal: true

module AnotherApi
  module OpenAPI
    # Builds OpenAPI path items from endpoint configurations.
    #
    # Operation responses assume the another_api response envelope:
    #   {success: bool, data: <object|array>, options?, metadata?: PaginationMetadata}
    # If your API ships a different envelope, subclass and override
    # #build_responses (or call SchemaBuilder yourself).
    class PathBuilder
      def initialize(endpoint_configs, known_schemas: nil, configuration: AnotherApi::OpenAPI.configuration)
        @endpoint_configs = endpoint_configs
        @known_schemas = known_schemas
        @configuration = configuration
      end

      def build_all
        paths = {}
        @endpoint_configs.each do |endpoint|
          openapi_path = endpoint[:path].gsub(/:(\w+)/, '{\1}')
          paths[openapi_path] ||= {}
          paths[openapi_path][endpoint[:verb]] = build_operation(endpoint)
        end
        paths
      end

      private

      def build_operation(endpoint)
        operation = {
          operationId: endpoint[:operation_id],
          tags: endpoint[:tags],
          summary: endpoint[:summary],
          description: endpoint[:description],
          parameters: build_parameters(endpoint),
          responses: build_responses(endpoint)
        }

        if endpoint[:schema_ref]
          if endpoint[:action] == "create"
            operation[:requestBody] = build_request_body(endpoint, "Create")
          elsif endpoint[:action] == "update"
            operation[:requestBody] = build_request_body(endpoint, "Update")
          end
        end

        operation.compact
      end

      def build_parameters(endpoint)
        params = []

        endpoint[:path].scan(/:(\w+)/).flatten.each do |param|
          params << {name: param, in: "path", required: true, schema: {type: "string"}}
        end

        endpoint[:custom_query_params]&.each do |qp|
          params << {
            name: qp[:name],
            in: "query",
            required: qp.fetch(:required, false),
            description: qp[:description],
            schema: {type: qp.fetch(:type, "string"), format: qp[:format]}.compact
          }.compact
        end

        return params unless endpoint[:action] == "index"

        concerns = endpoint[:concerns] || []

        if concerns.include?(:paginated)
          params << {"$ref" => "#/components/parameters/page"}
          params << {"$ref" => "#/components/parameters/page_size"}
        end
        if concerns.include?(:filtered_and_sorted)
          params << {"$ref" => "#/components/parameters/filter"}
          params << {"$ref" => "#/components/parameters/sort"}
        end
        if concerns.include?(:schema_configurable)
          params << {"$ref" => "#/components/parameters/variant"}
        end
        if concerns.include?(:filter_on_deleted)
          params << {"$ref" => "#/components/parameters/deleted"}
        end
        if concerns.include?(:filter_on_active)
          params << {"$ref" => "#/components/parameters/active"}
        end

        params
      end

      def build_responses(endpoint)
        schema_ref = endpoint[:schema_ref]
        responses = {}

        data_schema = if schema_ref
          {"$ref" => "#/components/schemas/#{schema_ref}"}
        else
          {type: "object"}
        end

        case endpoint[:action]
        when "index"
          responses["200"] = {
            description: "Success",
            content: {"application/json" => {
              schema: {
                type: "object",
                properties: {
                  success: {type: "boolean"},
                  data: {type: "array", items: data_schema},
                  options: {type: "object"},
                  metadata: {"$ref" => "#/components/schemas/PaginationMetadata"}
                }
              }
            }}
          }
        when "show"
          responses["200"] = success_data_response("Success", data_schema)
        when "create"
          responses["201"] = success_data_response("Created", data_schema)
        when "update"
          responses["200"] = success_data_response("Updated", data_schema)
        when "destroy"
          responses["200"] = {
            description: "Deleted",
            content: {"application/json" => {
              schema: {
                type: "object",
                properties: {
                  success: {type: "boolean"},
                  message: {type: "string"}
                }
              }
            }}
          }
        end

        error_content = @configuration.error_response_content
        responses["400"] = {description: "Bad request", content: error_content}
        responses["401"] = {description: "Unauthorized", content: error_content}
        responses["403"] = {description: "Forbidden", content: error_content}
        responses["404"] = {description: "Not found", content: error_content} if endpoint[:action] != "index"

        responses
      end

      def success_data_response(description, data_schema)
        {
          description: description,
          content: {"application/json" => {
            schema: {
              type: "object",
              properties: {
                success: {type: "boolean"},
                data: data_schema
              }
            }
          }}
        }
      end

      def build_request_body(endpoint, action_name)
        return nil unless endpoint[:schema_ref]
        base_name = endpoint[:schema_ref].delete_suffix("Full")
        ref_name = "#{base_name}#{action_name}Input"

        schema = if @known_schemas&.include?(ref_name)
          {"$ref" => "#/components/schemas/#{ref_name}"}
        else
          {type: "object"}
        end

        {required: true, content: {"application/json" => {schema: schema}}}
      end
    end
  end
end
