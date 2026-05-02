module AnotherApi
  module Authentication
    extend ActiveSupport::Concern

    included do
      attr_reader :current_api_token, :current_bearer
    end

    private

    def authenticate_with_api_token
      authenticate_with_http_token do |raw_token, _options|
        @started_processing_request_at = Time.zone.now
        @current_api_token = AnotherApi.configuration.token_model_class.find_by_token(raw_token)
        if @current_api_token&.active?
          @current_bearer = @current_api_token.bearer
          after_successful_authentication(@current_api_token, @current_bearer)
          true
        else
          false
        end
      end || request_http_token_authentication
    end

    # Override to set Current.*, log, or otherwise react to a successful auth.
    def after_successful_authentication(token, bearer)
    end

    def request_http_token_authentication(realm = "API", _message = nil)
      headers["WWW-Authenticate"] = %(Bearer realm="#{realm.tr('"', "")}")
      respond_to do |format|
        format.json { render json: json_error_body("unauthorized", "Unauthorized. Please authenticate with a Bearer token."), status: :unauthorized }
        format.any { head :unauthorized }
      end
    end

    def json_error_body(type, message)
      {success: false, error_type: type, error_message: message}
    end
  end
end
