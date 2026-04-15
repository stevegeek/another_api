module ApiSerializer
  # The transformer assumes input data uses symbolised keys. Convert before
  # passing if your input uses strings.
  class DataTransformer
    def initialize(target_data_structure)
      @target_data_structure = target_data_structure

      if @target_data_structure.attribute_names.empty?
        raise Errors::VariantDefinitionError, "You are trying to create a data transformer (#{@target_data_structure}) but no target attributes are defined, have you forgotten to define some?"
      end
    end

    attr_reader :target_data_structure

    def transform(data, context = {})
      mapped_data = perform_transform_and_mapping(data, context)
      @target_data_structure.new(**mapped_data)
    rescue Literal::TypeError, ArgumentError => e
      message = "The data transform failed as the data does not abide to the schema. \"#{e.message}\" - on (#{@target_data_structure.name})"
      raise Errors::DataTransformError, message
    end

    def inspect
      "#<#{self.class.name} (#{@target_data_structure.inspect})>"
    end

    def ==(other)
      target_data_structure == other.target_data_structure
    end

    alias_method :eql?, :==

    private

    def perform_transform_and_mapping(data, context)
      @target_data_structure.attribute_names.each_with_object({}) do |attribute_name, hash|
        attr = @target_data_structure.reflect_on(attribute_name)

        # has_value distinguishes "explicit nil" from "missing".
        value, has_value = attribute_mapping_to(attr, data, context)
        next unless has_value

        if attr.decompose?
          # FIXME: decomposition re-runs the mapping once per decomposed attribute;
          # it only needs to run once and splat the result.
          attrs = decomposed_attributes(attr, value)
          hash.merge!(attrs)
        else
          hash[attribute_name] = value
        end
      end
    end

    def decomposed_attributes(attr, value)
      return {} unless value.is_a?(Array)
      attr.decompose_to.each_with_object({}).with_index do |(decompose_to_attribute_name, hash), index|
        v = value[index]
        hash[decompose_to_attribute_name] = v unless v.nil?
      end
    end

    def attribute_mapping_to(attr, data, context)
      if attr.decompose?
        attribute_extracted_via_callable_and_path(attr, data, context)
      elsif attr.convert_by.is_a?(Proc) && attr.from_path
        attribute_extracted_via_callable_and_path(attr, data, context)
      elsif attr.convert_by.is_a?(Proc)
        attribute_extracted_via_callable(attr, data, context)
      elsif attr.from_path
        attribute_extracted_from_path(attr.from_path, data)
      else
        access_attribute(data, attr.name)
      end
    end

    def attribute_extracted_via_callable_and_path(attr, data, context)
      value_from_path, has_value = attribute_extracted_from_path(attr.from_path, data)
      return [nil, false] unless has_value
      attribute_extracted_via_callable(attr, value_from_path, context)
    end

    def attribute_extracted_via_callable(attr, data, context)
      callable = attr.convert_by
      if attr.compose?
        argc = attr.composed_of.size
        values = attr.composed_of.map { |path| attribute_extracted_from_path(path, data) }
        return [nil, false] unless values.all? { |v, has_v| has_v }
        values = values.map(&:first)
        if callable.arity == argc
          [callable.call(*values), true]
        elsif callable.arity == argc + 1
          [callable.call(*values, context), true]
        else
          raise Errors::AttributeDefinitionError, "The callable must accept #{argc} arguments (or #{argc + 1} arguments where the last is the context)"
        end
      elsif callable.arity == 1
        [callable.call(data), true]
      elsif callable.arity == 2
        [callable.call(data, context), true]
      else
        raise Errors::AttributeDefinitionError, "The callable must accept 1 argument (or 2 arguments where the last is the context)"
      end
    end

    def attribute_extracted_from_path(from_path, data)
      value = from_path.split(".").reduce(data) do |object, path_part|
        value, has_value = access_attribute(object, path_part)
        return [nil, false] unless has_value
        value
      end
      [value, true]
    end

    def access_attribute(object, attribute_name)
      symbolized_attribute_name = attribute_name.to_sym
      if object.respond_to?(:key?) && object.key?(symbolized_attribute_name)
        [object[symbolized_attribute_name], true]
      else
        call_getter(object, symbolized_attribute_name)
      end
    end

    def call_getter(object, attribute_name)
      if object.respond_to?(attribute_name) && object.method(attribute_name).arity == 0
        [object.send(attribute_name), true]
      else
        [nil, false]
      end
    end
  end
end
