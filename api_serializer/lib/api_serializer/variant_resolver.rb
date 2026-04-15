module ApiSerializer
  class VariantResolver
    # Fallback chain for nested association serialization: when the requested
    # variant doesn't exist on a nested schema, try these in order.
    NESTED_FALLBACKS = [:nested, :minimal, :id_only].freeze

    def initialize(variant_store, type, variant_mappings = {})
      @variant_store = variant_store
      @type = type
      @variant_mappings = variant_mappings
    end

    def resolve(name)
      @variant_store.fetch(@type, target_variant_name(name), abstract: false, raise_error: true)
    end

    def resolve_with_nested_fallback(name)
      resolve(name)
    rescue Errors::VariantNotFoundError
      NESTED_FALLBACKS.each do |fallback|
        next if fallback == target_variant_name(name)
        begin
          return resolve(fallback)
        rescue Errors::VariantNotFoundError
          next
        end
      end
      raise Errors::VariantNotFoundError, "No suitable variant found for nested serialization (tried #{name}, then #{NESTED_FALLBACKS.join(", ")})"
    end

    def resolve_transformer(name)
      resolve(name).transformer
    end

    private

    def target_variant_name(variant_name)
      return variant_name unless variant_mapped?

      @variant_mappings&.fetch(variant_name, nil) || variant_name
    end

    def variant_mapped?
      @variant_mappings.is_a?(Hash)
    end
  end
end
