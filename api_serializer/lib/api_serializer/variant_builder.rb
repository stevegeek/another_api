module ApiSerializer
  class VariantBuilder
    def initialize(name:, schema:, type: :serializer, abstract: false, parent: nil, mixins: [])
      @type = type
      @abstract = abstract
      @schema = schema
      @parent = parent
      @variant_name = name
      @mixins = mixins
    end

    def build(&)
      create_serialization_variant
      define_variant_name_method
      schema_description_and_name
      define_composed_with
      apply_mixins
      setup_attributes(&)
      determine_class_of_variant.new(name: @variant_name, serialization: @serialization_variant, inherits: @parent)
    end

    private

    def parent_serialization_class
      @parent&.serialization || (@abstract ? AbstractSerialization : Serialization)
    end

    def new_temporary_class_name
      @new_temporary_class_name ||= "api_serializer/#{@variant_name.to_s.gsub(/(?:^|_)(.)/) { Regexp.last_match(1).upcase }}Serialization<#{@schema.name}[:#{@variant_name}]>"
    end

    def create_serialization_variant
      serialization_variant = Class.new(parent_serialization_class)
      serialization_variant.set_temporary_name(new_temporary_class_name)
      @serialization_variant = serialization_variant
    end

    def define_variant_name_method
      new_variant_name = @variant_name
      @serialization_variant.define_singleton_method(:variant_name) { new_variant_name }
    end

    def schema_description_and_name
      base_name = parent_serialization_class.variant_name if parent_serialization_class.respond_to?(:variant_name)
      mixin_names = @mixins&.map(&:name)
      mixin_names_str = (mixin_names && !mixin_names.empty?) ? " composes templates/variants: [:#{mixin_names.join(", :")}]" : nil
      inherits = base_name ? " inherits from template/variant: [:#{base_name}]" : ""
      inherits += mixin_names_str if mixin_names_str
      define_schema_name_method(inherits)
    end

    def define_schema_name_method(inherits)
      class_inspect_str = "#{new_temporary_class_name}#{inherits}"
      @serialization_variant.define_singleton_method(:schema_name) { class_inspect_str }
    end

    def define_composed_with
      mixins = @mixins
      @serialization_variant.define_singleton_method(:composed_with) { mixins }
    end

    def apply_mixins
      return if @mixins.nil? || @mixins.empty?
      @mixins.each do |variant|
        serialization = variant.serialization
        if serialization.respond_to?(:attribute_definitions) && serialization.attribute_definitions
          @serialization_variant.instance_eval(&serialization.attribute_definitions)
        end
      end
    end

    def setup_attributes(&block)
      return unless block
      @serialization_variant.define_singleton_method(:attribute_definitions) { block }

      @serialization_variant.instance_eval(&block)
    end

    def determine_class_of_variant
      case @type
      when :serializer
        if @abstract
          Variants::SerializerTemplate
        else
          Variants::Serializer
        end
      when :deserializer
        if @abstract
          Variants::DeserializerTemplate
        else
          Variants::Deserializer
        end
      when :base
        Variants::BaseTemplate
      else
        raise ArgumentError, "Unknown variant type: #{@type}"
      end
    end
  end
end
