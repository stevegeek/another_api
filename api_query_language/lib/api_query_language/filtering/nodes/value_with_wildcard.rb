require "uri"

module ApiQueryLanguage
  module Filtering
    module Nodes
      # `parts` is a 2- or 3-element array. For 2, either the first or last
      # element is a "*" or "+" wildcard and the other is the value. For 3,
      # the first and last are both wildcards and the middle is the value.
      ValueWithWildcard = Data.define(:parts) do
        def decoded_value
          URI.decode_uri_component(value)
        end

        def wildcard_start? = wildcard?(parts.first)
        def wildcard_end? = wildcard?(parts.last)

        def value
          case parts
          in ["*" | "+", value] then value
          in [value, "*" | "+"] then value
          in ["*" | "+", value, "*" | "+"] then value
          else raise "Invalid wildcard value: #{parts}"
          end
        end

        def wildcards
          case parts
          in ["*" | "+" => t, _] then [t, nil]
          in [_, "*" | "+" => t] then [nil, t]
          in ["*" | "+" => first, _, "*" | "+" => last] then [first, last]
          else raise "Invalid wildcard value: #{parts}"
          end
        end

        private

        def wildcard?(part)
          part == "+" || part == "*"
        end
      end
    end
  end
end
