module ApiSerializer
  class Serialization
    extend ::Literal::Types

    class << self
      def inherited(subclass)
        struct = target_data_structure
        subclass.instance_exec do
          @target_data_structure = Class.new(struct)
          @target_data_structure_inherits_from = "(inherited from #{struct.name})" if struct.name
        end
        super
      end

      def attribute(name, type = _Any, reader: :public, positional: false, default: nil, from: nil, to: nil, transform: nil, queryable: nil, &coercer)
        from_or_name = from || to || name.to_s
        define_schema_attribute(name, type, reader:, positional:, default:, from: from_or_name, transform:, queryable:, &coercer)
      end

      def compose(name, type = _Any, from: nil, reader: :public, positional: false, default: nil, &composer)
        raise ArgumentError, "The 'from' option must be an array of attribute names" unless from.is_a?(Array)
        raise ArgumentError, "You must provide a 'compose' block with signature `|#{from.join(", ")}(, context)|`" unless composer

        define_schema_attribute(name, type, composed_of: from.map(&:to_s), transform: composer, reader:, positional:, default:)
      end

      def decompose(names, type = _Any, from:, reader: :public, positional: false, default: nil, &decomposer)
        raise ArgumentError, "The 'names' option must be an array of attribute names" unless names.is_a?(Array)
        raise ArgumentError, "You must provide a 'decompose' block with signature `|#{from}|` which returns #{names.size} values in an array" unless decomposer

        names.each do |name|
          define_schema_attribute(name.to_sym, type, from:, decompose_to: names.map(&:to_sym), transform: decomposer, reader: reader, positional: positional, default: default)
        end
      end

      def virtual(name, type = _Any, reader: :public, positional: false, default: nil, from: nil, &coercer)
        define_schema_attribute(name, type, reader:, positional:, default:, from:, transform: coercer, virtual: true)
      end

      def has_one(attribute_name, serializer_variant_resolver, reader: :public, positional: false, default: nil, from: nil, to: nil, virtual: false, queryable: nil, &coercer)
        association_attribute(attribute_name, serializer_variant_resolver, reader:, positional:, default:, from:, to:, virtual:, collection: false, queryable:, &coercer)
      end

      def has_many(attribute_name, serializer_variant_resolver, reader: :public, positional: false, default: nil, from: nil, to: nil, virtual: false, queryable: nil, &coercer)
        association_attribute(attribute_name, serializer_variant_resolver, reader:, positional:, default:, from:, to:, virtual:, collection: true, queryable:, &coercer)
      end

      # schema_name and composed_with are overridden by VariantBuilder when it
      # produces a concrete serialization subclass. Calling them on the base
      # class is a programmer error — flag it rather than returning nonsense.
      def schema_name
        raise NoMethodError, "schema_name is set by VariantBuilder on concrete serialization subclasses"
      end

      def composed_with
        raise NoMethodError, "composed_with is set by VariantBuilder on concrete serialization subclasses"
      end

      def reflect_on(name)
        attribute_options[name]
      end

      def attribute_options
        target_data_structure.attribute_options
      end

      def target_data_structure
        @target_data_structure ||= begin
          data_class = ::Class.new(TargetDataStructure)
          data_class.set_temporary_name("target_data_structure/#{name}")
          data_class
        end
      end

      def attribute_names
        target_data_structure.attribute_names
      end

      def filtering_mapped_attributes(depth: 1)
        mapped_attribute_paths(:filterable?, depth:)
      end

      def sorting_mapped_attributes(depth: 1)
        mapped_attribute_paths(:sortable?, depth:)
      end

      def transformer
        target_data_structure.set_temporary_name("target_data_structure/#{name}#{" (#{@target_data_structure_inherits_from})" if @target_data_structure_inherits_from}")
        DataTransformer.new(target_data_structure)
      end

      private

      def define_schema_attribute(attribute_name, type = _Any, reader: :public, positional: false, default: nil, from: nil, to: nil, virtual: false, composed_of: nil, decompose_to: nil, transform: nil, queryable: nil, nested_schema: nil, &coercer)
        from = from.to_s if from.is_a?(Symbol)
        to = to.to_s if to.is_a?(Symbol)
        type = Literal::Types::NilableType.new(type) unless default.nil?
        target_data_structure.attribute(
          attribute_name,
          type,
          reader:,
          positional:,
          default:,
          composed_of:,
          decompose_to:,
          convert_by: transform,
          from_path: from || to,
          virtual:,
          queryable:,
          nested_schema:,
          &coercer
        )
      end

      def association_attribute(attribute_name, serializer_variant_resolver, reader: :public, positional: false, default: nil, from: nil, to: nil, virtual: false, collection: false, queryable: nil, &coercer)
        attribute_type = association_type(serializer_variant_resolver, collection)
        unwrapped_resolver = if serializer_variant_resolver.is_a?(::Literal::Types::NilableType)
          serializer_variant_resolver.instance_variable_get(:@type)
        else
          serializer_variant_resolver
        end

        target_data_structure.attribute(
          attribute_name,
          attribute_type,
          reader:,
          positional:,
          default:,
          convert_by: proc do |value, context|
            variant_name = context[:current_variant_name] || :full
            value = coercer.call(value, context) if coercer
            if value && !collection
              unwrapped_resolver.resolve_with_nested_fallback(variant_name).transform(value, context)
            elsif value
              value.map { |v| unwrapped_resolver.resolve_with_nested_fallback(variant_name).transform(v, context) }
            end
          rescue Errors::VariantNotFoundError
            nil
          end,
          from_path: from || to || attribute_name.to_s,
          virtual:,
          queryable:,
          nested_schema: unwrapped_resolver,
          &coercer
        )
      end

      def mapped_attribute_paths(predicate, depth:)
        return {} if depth > 5

        attribute_options.each_with_object({}) do |(name, attr), hash|
          next unless attr.public_send(predicate)

          if attr.association?
            nested_serialization = attr.nested_schema.resolve_with_nested_fallback(:full).serialization
            nested = (predicate == :filterable?) ?
              nested_serialization.filtering_mapped_attributes(depth: depth + 1) :
              nested_serialization.sorting_mapped_attributes(depth: depth + 1)
            prefix = attr.from_path || name.to_s
            nested.each do |nested_name, nested_mapped|
              hash[:"#{name}.#{nested_name}"] = "#{prefix}.#{nested_mapped || nested_name}"
            end
          else
            # nil signals "use the attribute name directly as the DB column".
            explicit_column = attr.query_column || (attr.from_path if attr.from_path != name.to_s)

            hash[name] = if attr.query_transform || attr.allowed_values
              QueryableConfig.new(
                filter: attr.filterable?,
                sort: attr.sortable?,
                column: explicit_column,
                transform: attr.query_transform,
                allowed_values: attr.allowed_values
              )
            else
              explicit_column
            end
          end
        end
      end

      def association_type(serializer_variant_resolver, collection)
        core_type = collection ? _Union(Array(_Any), Array) : _Any
        if serializer_variant_resolver.is_a?(::Literal::Types::NilableType)
          ::Literal::Types::NilableType.new(core_type)
        elsif serializer_variant_resolver.is_a?(VariantResolver)
          core_type
        else
          raise Errors::VariantDefinitionError, "serializer_variant must be a VariantResolver or _Nilable(VariantResolver), got #{serializer_variant_resolver.class}"
        end
      end
    end
  end
end
