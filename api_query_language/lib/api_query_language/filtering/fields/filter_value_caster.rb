require "bigdecimal"

module ApiQueryLanguage
  module Filtering
    module Fields
      # type_caster must duck-type two methods:
      #   .type        → Symbol drawn from SUPPORTED_TYPES
      #   .cast(value) → typed value or nil
      # The AR column type_caster satisfies this; consumers can inject their own.
      class FilterValueCaster
        SUPPORTED_TYPES = %i[boolean date datetime decimal float integer string text time].freeze
        BOOLEAN_TRUE_VALUES = %w[1 t T true TRUE True on ON yes Y y].freeze
        BOOLEAN_FALSE_VALUES = %w[0 f F false FALSE False off OFF no N n].freeze

        def initialize(type_caster, supported_types: SUPPORTED_TYPES)
          raise Errors::UnsupportedFieldTypeError.new(type_caster.type) unless supported_types.include?(type_caster.type)

          @type_caster = type_caster
        end

        def cast(value)
          raise ArgumentError, "Value must be a string" unless value.is_a?(String)

          case type
          when :integer, :decimal, :float
            raise Errors::InvalidFieldValueError.new(type, value) unless numeric_value?(value)
            convert_numeric(value)
          when :boolean
            if BOOLEAN_TRUE_VALUES.include?(value)
              true
            elsif BOOLEAN_FALSE_VALUES.include?(value)
              false
            else
              raise Errors::InvalidFieldValueError.new(type, value)
            end
          else
            @type_caster.cast(value).tap do |casted_value|
              raise Errors::InvalidFieldValueError.new(@type_caster.type, value) if casted_value.nil?
            end
          end
        end

        private

        def type = @type_caster.type

        def numeric_value?(value)
          value.match?(/\A-?[\d.]+\z/)
        end

        def convert_numeric(value)
          case type
          when :integer then value.to_i
          when :decimal then BigDecimal(value)
          when :float then value.to_f
          else raise Errors::UnsupportedFieldTypeError.new(type)
          end
        end
      end
    end
  end
end
