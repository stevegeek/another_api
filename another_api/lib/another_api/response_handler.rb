module AnotherApi
  module ResponseHandler
    extend ActiveSupport::Concern

    include Dry::Monads[:result]

    def api_respond_to_json
      respond_to do |format|
        format.json do
          case yield
          in Success(data: data, status: status, **params)
            response = {success: true, data: data}
            response.merge!(params) if params.present?
            render status: status, json: response
          in Success(data: data, **params)
            response = {success: true, data: data}
            response.merge!(params) if params.present?
            render status: :ok, json: response
          in Success(String => message)
            render status: :ok, json: {success: true, message: message}
          in Success(data)
            render status: :ok, json: {success: true, data: data}
          in Success()
            head :no_content

          in Failure[type, ::ActiveRecord::Base => model]
            response = {success: false, error_type: type, error_message: "Validation failed: #{model.errors.full_messages.join(", ")}", errors: model.errors}
            render status: error_status_for(type), json: response
          in Failure[type, String => message, *others]
            response = {success: false, error_type: type, error_message: message}
            response[:details] = others if others.present?
            render status: error_status_for(type), json: response
          in Failure(AnotherApi::OperationFailure[type, String => message, *others])
            response = {success: false, error_type: type, error_message: message}
            response[:details] = others if others.present?
            render status: error_status_for(type), json: response
          in Failure(:not_found)
            raise AnotherApi::NotFoundError, "Not found"
          in Failure(:not_permitted) | Failure(:forbidden)
            raise AnotherApi::ForbiddenError, "Forbidden"
          in Failure(:bad_request)
            raise AnotherApi::BadRequestError, "Bad request"
          in Failure(Symbol => type)
            head error_status_for(type)
          end
        rescue ::ActiveRecord::RecordInvalid => e
          render status: :bad_request, json: {success: false, error_type: "validation_error", error_message: "Validation failed", errors: e.record.errors}
        rescue ::ActiveModel::ValidationError => e
          render status: :bad_request, json: {success: false, error_type: "validation_error", error_message: "Validation failed", errors: e.model.errors}
        rescue ::ActionController::ParameterMissing => e
          render status: :bad_request, json: {success: false, error_type: "missing_parameter", error_message: e.message}
        end
      end
    end

    def raise_forbidden(message = "Forbidden")
      raise AnotherApi::ForbiddenError, message
    end

    def raise_bad_request(message = "Bad Request")
      raise AnotherApi::BadRequestError, message
    end

    def raise_not_found(message = "Not Found")
      raise AnotherApi::NotFoundError, message
    end

    private

    def error_status_for(type)
      AnotherApi.configuration.error_status_map.fetch(type, :bad_request)
    end
  end
end
