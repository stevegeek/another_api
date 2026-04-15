module AnotherApi
  class OperationFailure < Data.define(:code, :message, :details)
    def self.new(code, message = nil, *details)
      super(code: code, message: message, details: details)
    end

    # Explicit deconstruct so ResponseHandler's pattern match —
    # `in Failure(OperationFailure[type, String => message, *others])` —
    # sees [code, message, *details] rather than the default 3-tuple.
    def deconstruct
      [code, message, *details]
    end
  end
end
