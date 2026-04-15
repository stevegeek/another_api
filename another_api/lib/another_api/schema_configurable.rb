module AnotherApi
  module SchemaConfigurable
    def parse_requested_variant_for(schema_klass)
      variant = sanitise_query_param(request.query_parameters[:variant]&.to_s, strip_out: /[^a-zA-Z0-9.-_]/)&.to_sym
      return variant if variant && schema_klass.variant?(variant)
      :full
    end
  end
end
