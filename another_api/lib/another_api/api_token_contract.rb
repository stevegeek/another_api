module AnotherApi
  module ApiTokenContract
    extend ActiveSupport::Concern

    included do
      belongs_to :bearer, polymorphic: true
    end

    def allows?(requested_scope)
      parsed_scopes.any? { |s| s.matches?(requested_scope) }
    end

    def parsed_scopes
      @parsed_scopes ||= scopes.map { |s| AnotherApi::Scope.parse(s) }
    end

    def active?
      !revoked? && !expired?
    end

    def revoked?
      revoked_at.present?
    end

    def expired?
      expires_at&.past? || false
    end

    def token_preview
      "#{token_prefix}#{"*" * 12}#{token_suffix}"
    end

    module ClassMethods
      def find_by_token(raw_token)
        digest = AnotherApi::TokenGeneration.digest(raw_token)
        find_by(token_digest: digest)
      end
    end
  end
end
