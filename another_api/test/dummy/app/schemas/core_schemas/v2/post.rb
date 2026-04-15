# frozen_string_literal: true

module CoreSchemas
  module V2
    class Post < ApiSerializer::Schema
      serializer :default do
        attribute :id, Integer, queryable: {sort: true, filter: false}
        attribute :title, String, queryable: {sort: true, filter: true}
        attribute :body, _Nilable(String)
        # These cover the apply-time error paths in FilteredAndSorted:
        # - status filters with allowed_values → DisallowedValueError on bad value
        # - missing_column maps filtering to a column that doesn't exist on the model
        #   → InvalidFieldError at apply-time
        attribute :status, _Nilable(String), queryable: {filter: true, allowed_values: %w[draft published]}
        attribute :missing_column, _Nilable(String),
          queryable: {filter: true, sort: true, column: "definitely_not_a_real_column"}
      end

      deserializer :create do
        attribute :title, String
        attribute :body, _Nilable(String)
      end
    end
  end
end
