require "test_helper"

module ApiQueryLanguage
  module Filtering
    module Nodes
      class ValueTest < ::ApiQueryLanguageTestCase
        def setup
          @value = Value.new(value: "value%20")
        end

        def test_nil_value
          assert_nil Value.new(value: nil).decoded_value
        end

        def test_nil?
          assert Value.new(value: nil).nil?
          refute Value.new(value: "value").nil?
        end

        def test_decoded_value
          assert_equal "value ", @value.decoded_value
        end

        def test_value
          assert_equal "value%20", @value.value
        end

        def test_invalid_value
          assert_raises ArgumentError do
            Value.new(value: "%value").decoded_value
          end
        end
      end
    end
  end
end
