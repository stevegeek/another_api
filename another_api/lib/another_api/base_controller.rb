module AnotherApi
  class BaseController < ::ActionController::API
    include ::ActionController::HttpAuthentication::Token::ControllerMethods
    include ::ActionController::MimeResponds
    include ActionPolicy::Controller
    include AnotherApi::ParamSanitizer
    include AnotherApi::Authentication
    include AnotherApi::ErrorHandling
    include AnotherApi::ResponseHandler
    include AnotherApi::SchemaConfigurable
    include AnotherApi::Paginated
    include AnotherApi::ResponseHasMetadata

    prepend_before_action :authenticate_with_api_token

    authorize :api_token, through: :current_api_token
    authorize :bearer, through: :current_bearer

    attr_reader :started_processing_request_at

    private

    def json_error_body(type, message)
      {success: false, error_type: type, error_message: message}
    end
  end
end
