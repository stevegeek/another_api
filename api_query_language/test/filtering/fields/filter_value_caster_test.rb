require "test_helper"

module ApiQueryLanguage
  module Filtering
    module Fields
      class FilterValueCasterTest < ::ApiQueryLanguageTestCase
        # Minimal duck-typed caster stub matching the expected interface:
        #   .type        → Symbol
        #   .cast(value) → typed value or nil
        FakeTypeCaster = Struct.new(:type) do
          def cast(value)
            case type
            when :string, :text then value.to_s
            when :boolean
              case value
              when "true", "t", "1" then true
              when "false", "f", "0" then false
              end
            else value
            end
          end
        end

        # --- Unsupported type guard ---

        test "raises when type_caster reports an unsupported type" do
          assert_raises(::ApiQueryLanguage::Errors::UnsupportedFieldTypeError) do
            FilterValueCaster.new(FakeTypeCaster.new(:jsonb))
          end
        end

        test "allows caller to restrict supported_types" do
          assert_raises(::ApiQueryLanguage::Errors::UnsupportedFieldTypeError) do
            FilterValueCaster.new(FakeTypeCaster.new(:integer), supported_types: %i[string])
          end
        end

        # --- Non-string input ---

        test "cast raises ArgumentError on non-string input" do
          caster = FilterValueCaster.new(FakeTypeCaster.new(:string))
          assert_raises(ArgumentError) { caster.cast(42) }
        end

        # --- Numeric conversion ---

        test "cast integer parses a numeric string" do
          assert_equal 42, FilterValueCaster.new(FakeTypeCaster.new(:integer)).cast("42")
        end

        test "cast integer accepts a decimal string and truncates via to_i" do
          assert_equal 42, FilterValueCaster.new(FakeTypeCaster.new(:integer)).cast("42.9")
        end

        test "cast integer rejects non-numeric input" do
          assert_raises(::ApiQueryLanguage::Errors::InvalidFieldValueError) do
            FilterValueCaster.new(FakeTypeCaster.new(:integer)).cast("abc")
          end
        end

        test "cast float parses to Float" do
          assert_equal 3.14, FilterValueCaster.new(FakeTypeCaster.new(:float)).cast("3.14")
        end

        test "cast decimal parses to BigDecimal (pure Ruby — require bigdecimal is shipped)" do
          result = FilterValueCaster.new(FakeTypeCaster.new(:decimal)).cast("1.5")
          assert_kind_of BigDecimal, result
          assert_equal BigDecimal("1.5"), result
        end

        # --- Boolean conversion — both sides fully covered ---

        test "cast boolean accepts every BOOLEAN_TRUE_VALUES entry" do
          caster = FilterValueCaster.new(FakeTypeCaster.new(:boolean))
          FilterValueCaster::BOOLEAN_TRUE_VALUES.each do |v|
            assert_equal true, caster.cast(v), "expected #{v.inspect} → true"
          end
        end

        test "cast boolean accepts every BOOLEAN_FALSE_VALUES entry" do
          caster = FilterValueCaster.new(FakeTypeCaster.new(:boolean))
          FilterValueCaster::BOOLEAN_FALSE_VALUES.each do |v|
            assert_equal false, caster.cast(v), "expected #{v.inspect} → false"
          end
        end

        test "cast boolean rejects values outside either list" do
          caster = FilterValueCaster.new(FakeTypeCaster.new(:boolean))
          assert_raises(::ApiQueryLanguage::Errors::InvalidFieldValueError) { caster.cast("maybe") }
        end

        # --- Fallback to injected type_caster for other types ---

        test "cast string delegates to the injected caster" do
          caster = FilterValueCaster.new(FakeTypeCaster.new(:string))
          assert_equal "hello", caster.cast("hello")
        end

        test "cast raises when the injected caster returns nil" do
          dud = FakeTypeCaster.new(:string)
          def dud.cast(_) = nil
          caster = FilterValueCaster.new(dud)
          assert_raises(::ApiQueryLanguage::Errors::InvalidFieldValueError) { caster.cast("x") }
        end
      end
    end
  end
end
