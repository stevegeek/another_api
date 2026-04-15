module AnotherApi
  module ParamSanitizer
    private

    # strip_out must be a caller-supplied (trusted) regex, never user input —
    # it is passed directly to gsub and unbounded patterns risk ReDoS. max_length
    # caps the input size which limits but does not eliminate that risk.
    def sanitise_query_param(str, max_length: 50, strip_out: nil)
      return unless str
      size_limited = str.to_s[0, max_length]
      strip_out ? size_limited.gsub(strip_out, "") : size_limited
    end
  end
end
