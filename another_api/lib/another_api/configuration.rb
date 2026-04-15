module AnotherApi
  class Configuration
    attr_accessor :token_model, :token_secret, :token_prefix,
      :scope_prefix, :default_page_size, :max_page_size,
      :error_status_map

    def initialize
      @token_model = "ApiToken"
      @token_secret = nil
      @token_prefix = "aa"
      @scope_prefix = "api.v2."
      @default_page_size = 20
      @max_page_size = 200
      @error_status_map = {
        bad_request: :bad_request,
        validation_error: :bad_request,
        unprocessable_content: :unprocessable_entity,
        not_found: :not_found,
        forbidden: :forbidden,
        unauthorized: :unauthorized,
        conflict: :conflict,
        not_acceptable: :not_acceptable
      }
      @rescue_registry = []
    end

    def rescue_from(exception_class_name, as:)
      @rescue_registry << {exception: exception_class_name, error_type: as}
    end

    attr_reader :rescue_registry

    # Fail fast at boot if the consumer has not configured required values.
    # Missing token_secret is especially bad: TokenGeneration.digest raises at
    # request time, triggering the StandardError rescue for every request.
    def validate!
      raise ConfigurationError, "AnotherApi.configuration.token_secret must be set" if token_secret.nil? || token_secret.to_s.empty?
      raise ConfigurationError, "AnotherApi.configuration.token_model must be set" if token_model.nil? || token_model.to_s.empty?
    end
  end

  class ConfigurationError < StandardError; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
