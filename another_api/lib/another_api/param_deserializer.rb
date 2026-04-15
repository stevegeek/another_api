module AnotherApi
  module ParamDeserializer
    private

    def deserialize_params(schema_class, variant, defaults: {})
      body_data = params.to_unsafe_h.symbolize_keys.except(:controller, :action, :format)
      data = defaults.merge(body_data)
      transformer = schema_class.deserializer_for(variant)
      coerce_params_to_schema_types!(data, transformer.target_data_structure)
      transformer.transform(data, {current_variant_name: variant})
    rescue ApiSerializer::Errors::DataTransformError => e
      raise AnotherApi::BadRequestError, e.message
    end

    def coerce_params_to_schema_types!(data, target_data_structure)
      target_data_structure.attribute_names.each do |attr_name|
        attr_opts = target_data_structure.reflect_on(attr_name)
        next unless attr_opts

        source_key = attr_opts.from_path ? attr_opts.from_path.to_sym : attr_name

        next unless data.key?(source_key)
        value = data[source_key]
        next unless value.is_a?(String)

        inner_type = attr_opts.type
        inner_type = inner_type.instance_variable_get(:@type) while inner_type.class.name&.include?("NilableType")

        type_name = inner_type.to_s

        if inner_type == Integer || type_name.include?("Integer")
          data[source_key] = Integer(value) if value.match?(/\A-?\d+\z/)
        elsif inner_type == Float || type_name.include?("Float")
          data[source_key] = Float(value) if value.match?(/\A-?\d+\.?\d*\z/)
        elsif inner_type == Numeric || type_name.include?("Numeric")
          data[source_key] = value.include?(".") ? Float(value) : Integer(value) if value.match?(/\A-?\d+\.?\d*\z/)
        elsif type_name.include?("Boolean") || inner_type == TrueClass || inner_type == FalseClass
          data[source_key] = ActiveModel::Type::Boolean.new.cast(value)
        end
      rescue
        nil
      end
    end
  end
end
