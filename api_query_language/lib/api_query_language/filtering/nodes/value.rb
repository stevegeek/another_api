require "uri"

module ApiQueryLanguage
  module Filtering
    module Nodes
      Value = Data.define(:value) do
        def decoded_value
          return if nil?
          URI.decode_uri_component(value)
        end

        def nil?
          value.nil?
        end
      end
    end
  end
end
