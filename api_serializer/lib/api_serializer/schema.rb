module ApiSerializer
  class Schema
    class << self
      def inherited(subclass)
        subclass.instance_variable_set(:@schema_variants_store, @schema_variants_store.clone) if @schema_variants_store
        super
      end

      attr_reader :schema_variants_store

      def base_template(name, inherits: nil, &)
        define_variant(name, abstract: true, type: :base, inherits:, composes: nil, &)
      end

      def serializer_template(name, inherits: nil, composes: nil, &)
        define_variant(name, abstract: true, type: :serializer, inherits:, composes:, &)
      end

      def deserializer_template(name, inherits: nil, composes: nil, &)
        define_variant(name, abstract: true, type: :deserializer, inherits:, composes:, &)
      end

      # Called without a variant name, returns a VariantResolver — use this at
      # require time when referring to another schema whose variants may not
      # have been defined yet.
      def serializer(variant_name = nil, inherits: nil, composes: nil, &)
        define_variant_or_build_resolver(:serializer, variant_name, inherits: inherits, composes: composes, &)
      end

      def deserializer(variant_name = nil, inherits: nil, composes: nil, &)
        define_variant_or_build_resolver(:deserializer, variant_name, inherits: inherits, composes: composes, &)
      end

      def serializer_for(variant_name)
        serializer.resolve_transformer(variant_name)
      end

      def deserializer_for(variant_name)
        deserializer.resolve_transformer(variant_name)
      end

      def variant?(variant_name, type: :serializer)
        !!fetch_variant(type, false, variant_name.to_sym)
      end

      def fetch_variant(type, abstract, variant_name)
        @schema_variants_store&.fetch(type, variant_name, abstract:)
      end

      private

      def define_variant_or_build_resolver(type, variant_name_or_mappings = nil, inherits: nil, composes: nil, &)
        if variant_name_or_mappings.is_a?(Symbol) || variant_name_or_mappings.is_a?(String)
          define_variant(variant_name_or_mappings, type: type, inherits:, composes:, &)
        else
          raise ArgumentError, "variant_name_or_mappings must be a Hash" unless variant_name_or_mappings.is_a?(Hash) || variant_name_or_mappings.nil?
          # Normalise mapping keys and values to symbols so `{ "full" => "minimal" }`
          # and `{ full: :minimal }` are equivalent.
          mappings = variant_name_or_mappings&.transform_keys(&:to_sym)&.transform_values { |v| v.respond_to?(:to_sym) ? v.to_sym : v }
          VariantResolver.new(@schema_variants_store, type, mappings)
        end
      end

      def define_variant(variant_name, type:, abstract: false, inherits: nil, composes: nil, &)
        variant_name = variant_name.to_sym
        existing_variant = fetch_variant(type, abstract, variant_name)
        variant_base = if inherits
          raise Errors::VariantDefinitionError, "Cannot inherit from multiple variants. Use composes: []" unless inherits.is_a?(Symbol)
          parent_variant = fetch_variant_with_fallback_to_base(type, abstract, inherits)
          parent_variant || existing_variant
        else
          existing_variant
        end
        mixins = composed_variants(composes, type, abstract) if composes && !composes.empty?
        new_serializer_variant = VariantBuilder.new(type:, abstract:, schema: self, parent: variant_base, name: variant_name, mixins:).build(&)
        store_new_variant(new_serializer_variant)
      end

      def composed_variants(composes, type, abstract)
        composes = composes.is_a?(Array) ? composes : [composes]
        composes.map(&:to_sym).map do |variant_to_compose|
          fetch_variant_with_fallback_to_base(type, abstract, variant_to_compose).tap do |variant|
            raise Errors::VariantDefinitionError, "Cannot mixin #{type} variant '#{variant_to_compose}' to #{self} as it does not exist" unless variant
          end
        end
      end

      def store_new_variant(variant)
        @schema_variants_store ||= VariantsStore.new
        @schema_variants_store.store(variant)
      end

      def fetch_variant_with_fallback_to_base(type, abstract, variant_name)
        @schema_variants_store&.fetch_with_fallback(type, variant_name, abstract:)
      end
    end
  end
end
