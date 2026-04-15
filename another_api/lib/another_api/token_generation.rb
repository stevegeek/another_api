module AnotherApi
  module TokenGeneration
    def self.generate(prefix: AnotherApi.configuration.token_prefix)
      body = SecureRandom.base58(24)
      token_prefix = SecureRandom.base58(4)
      token_suffix = SecureRandom.base58(4)
      raw_token = "#{prefix}_#{token_prefix}#{body}#{token_suffix}"
      {
        raw_token: raw_token,
        token_digest: digest(raw_token),
        token_prefix: token_prefix,
        token_suffix: token_suffix
      }
    end

    def self.digest(raw_token)
      secret = AnotherApi.configuration.token_secret
      if secret.nil? || secret.to_s.empty?
        raise ConfigurationError, "AnotherApi.configuration.token_secret must be set"
      end
      OpenSSL::HMAC.hexdigest("SHA256", secret, raw_token)
    end
  end
end
