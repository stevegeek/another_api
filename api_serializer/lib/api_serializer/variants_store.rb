module ApiSerializer
  class VariantsStore
    def initialize(variants = [])
      @store = {}
      variants.each { |variant| store(variant) }
    end

    def variants
      @store.values.flat_map(&:values)
    end

    def fetch(type, variant_name, abstract:, raise_error: false)
      type_store = @store[type_key(type, abstract)]
      variant = type_store[variant_name] if type_store
      raise Errors::VariantNotFoundError, "Variant #{variant_name} (abstract: #{abstract}, type: #{type}) not found" if raise_error && variant.nil?
      variant
    end

    def fetch_with_fallback(type, variant_name, abstract:, raise_error: false)
      if abstract
        fetch(type, variant_name, abstract: true) ||
          fetch(:base, variant_name, abstract: true) ||
          fetch(:base, variant_name, abstract: true, raise_error:)
      else
        fetch(type, variant_name, abstract: false) ||
          fetch(type, variant_name, abstract: true) ||
          fetch(:base, variant_name, abstract: true, raise_error:)
      end
    end

    def store(variant)
      key = type_key(variant.type, variant.abstract?)
      @store[key] ||= {}
      @store[key][variant.name] = variant
    end

    def type_key(type, abstract)
      prefix = abstract ? :fragment : :full
      "#{prefix}_#{type}"
    end

    def clone
      self.class.new(variants)
    end
  end
end
