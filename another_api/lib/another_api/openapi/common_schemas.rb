# frozen_string_literal: true

module AnotherApi
  module OpenAPI
    # Default OpenAPI schema components: parameters, pagination metadata,
    # error responses, and security schemes. Each method returns a fresh hash
    # so callers can mutate without surprising side effects. Configuration
    # references these as defaults; users can override any of them via
    # AnotherApi::OpenAPI.configure.
    module CommonSchemas
      module_function

      def default_parameters
        {
          page: {name: "page", in: "query", required: false, schema: {type: "integer", minimum: 1, default: 1}, description: "Page number"},
          page_size: {name: "page_size", in: "query", required: false, schema: {type: "integer", minimum: 1, maximum: 200, default: 20}, description: "Records per page (max 200)"},
          variant: {name: "variant", in: "query", required: false, schema: {type: "string", enum: %w[id_only minimal full]}, description: "Response detail level"},
          filter: {name: "filter", in: "query", required: false, schema: {type: "string"}, description: "Filter expression. Values must be URI-encoded."},
          sort: {name: "sort", in: "query", required: false, schema: {type: "string"}, description: "Sort expression. Format: field:asc or field:desc. Multiple fields separated by semicolons."},
          deleted: {name: "deleted", in: "query", required: false, schema: {type: "string", enum: %w[exclude include only], default: "exclude"}, description: "Include soft-deleted records"},
          active: {name: "active", in: "query", required: false, schema: {type: "string", enum: %w[only include exclude], default: "only"}, description: "Filter by active/inactive status"}
        }
      end

      def default_pagination_metadata
        {
          type: "object",
          properties: {
            offset: {type: "integer"},
            count: {type: "integer", description: "Records in current page"},
            total_count: {type: "integer", description: "Total records matching query"},
            total_pages: {type: "integer"},
            has_more: {type: "boolean"},
            request_id: {type: "string", format: "uuid"},
            request_started_at: {type: "string", format: "date-time"},
            request_ended_at: {type: "string", format: "date-time"},
            next_poll_at: {type: "string", format: "date-time"}
          }
        }
      end

      def default_error_response
        {"application/json" => {
          schema: {
            type: "object",
            properties: {
              success: {type: "boolean", enum: [false]},
              error_type: {type: "string"},
              error_message: {type: "string"}
            }
          }
        }}
      end

      def default_security_schemes
        {
          bearerAuth: {
            type: "http",
            scheme: "bearer",
            description: "API key token. Obtain from your account settings."
          }
        }
      end
    end
  end
end
