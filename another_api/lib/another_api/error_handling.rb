module AnotherApi
  module ErrorHandling
    extend ActiveSupport::Concern

    included do
      # Declared first deliberately: rescue_from uses LIFO order, so this
      # catch-all has the *lowest* priority and only fires when no specific
      # handler below matches. It also dispatches to consumer-declared
      # mappings from AnotherApi.configure at rescue time — this avoids any
      # class-load ordering between the gem and consumer initializers.
      rescue_from ::StandardError do |e|
        if (mapping = AnotherApi::ErrorHandling.mapping_for(e))
          status = AnotherApi.configuration.error_status_map.fetch(mapping[:error_type], :internal_server_error)
          respond_to do |format|
            format.json { render json: json_error_body(mapping[:error_type].to_s, e.message), status: status }
            format.any { head status }
          end
        else
          Rails.logger.error("[another_api] #{e.class}: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
          respond_to do |format|
            format.json { render json: json_error_body("internal_server_error", "An unexpected error occurred."), status: :internal_server_error }
            format.any { head :internal_server_error }
          end
        end
      end

      rescue_from AnotherApi::BadRequestError, ::ActionController::ParameterMissing do |e|
        respond_to do |format|
          format.json { render json: json_error_body("bad_request", e.message), status: :bad_request }
          format.any { head :bad_request }
        end
      end

      rescue_from AnotherApi::ForbiddenError, ::ActionPolicy::Unauthorized, ::ActionPolicy::NotFound do |e|
        respond_to do |format|
          format.json { render json: json_error_body("forbidden", "Forbidden. You do not have permissions to do this."), status: :forbidden }
          format.any { head :forbidden }
        end
      end

      rescue_from AnotherApi::NotFoundError, ::ActionController::RoutingError, ::ActiveRecord::RecordNotFound do
        respond_to do |format|
          format.json { render json: json_error_body("not_found", "Not found"), status: :not_found }
          format.any { head :not_found }
        end
      end

      rescue_from AnotherApi::UnprocessableError do |e|
        respond_to do |format|
          format.json { render json: json_error_body("unprocessable_entity", e.message), status: :unprocessable_entity }
          format.any { head :unprocessable_entity }
        end
      end

      rescue_from AnotherApi::NotAcceptableError, ::ActionController::UnknownFormat do |e|
        respond_to do |format|
          format.json { render json: json_error_body("not_acceptable", "Not acceptable. The API generally accepts and responds with application/json"), status: :not_acceptable }
          format.any { head :not_acceptable }
        end
      end
    end

    # Find the consumer-declared mapping (if any) whose exception class
    # matches `exception`. Exception classes are resolved lazily — a mapping
    # for an unloaded class matches nothing rather than raising.
    def self.mapping_for(exception)
      AnotherApi.configuration.rescue_registry.find do |mapping|
        klass = mapping[:exception].safe_constantize
        klass && exception.is_a?(klass)
      end
    end
  end
end
