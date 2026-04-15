module ApiSerializer
  class TargetDataStructure < TypedStruct
    class << self
      def attribute(name, type, from_path: nil, composed_of: nil, decompose_to: nil, convert_by: nil, virtual: false, queryable: nil, nested_schema: nil, **, &)
        super(name, type, **, &)

        @attribute_options[name] = AttributeOptions.new(@attribute_options[name], from_path:, composed_of:, decompose_to:, convert_by:, virtual:, queryable:, nested_schema:)
      end
    end

    def as_json(_options = nil)
      to_h.transform_values { |v| json_value(v) }
    end

    private

    def json_value(value)
      case value
      when TargetDataStructure then value.as_json
      when Array then value.map { |v| json_value(v) }
      else value
      end
    end
  end
end
