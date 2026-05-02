# frozen_string_literal: true

require "test_helper"
require "another_api/openapi"

class AnotherApi::OpenAPI::TypeMapperTest < Minitest::Test
  include Literal::Types

  def test_string
    assert_equal({type: "string"}, AnotherApi::OpenAPI::TypeMapper.map(String))
  end

  def test_integer
    assert_equal({type: "integer"}, AnotherApi::OpenAPI::TypeMapper.map(Integer))
  end

  def test_numeric_and_float
    assert_equal({type: "number"}, AnotherApi::OpenAPI::TypeMapper.map(Numeric))
    assert_equal({type: "number"}, AnotherApi::OpenAPI::TypeMapper.map(Float))
  end

  def test_time_uses_date_time_format
    assert_equal({type: "string", format: "date-time"}, AnotherApi::OpenAPI::TypeMapper.map(Time))
  end

  def test_hash
    assert_equal({type: "object"}, AnotherApi::OpenAPI::TypeMapper.map(Hash))
  end

  def test_bare_array_falls_back_to_string_items
    assert_equal({type: "array", items: {type: "string"}}, AnotherApi::OpenAPI::TypeMapper.map(Array))
  end

  def test_literal_boolean
    assert_equal({type: "boolean"}, AnotherApi::OpenAPI::TypeMapper.map(_Boolean))
  end

  def test_nilable_string_returns_string_or_null
    result = AnotherApi::OpenAPI::TypeMapper.map(_Nilable(String))
    assert_equal ["string", "null"], result[:type]
  end

  def test_nilable_integer_returns_integer_or_null
    result = AnotherApi::OpenAPI::TypeMapper.map(_Nilable(Integer))
    assert_equal ["integer", "null"], result[:type]
  end

  def test_typed_array_uses_inner_mapping
    result = AnotherApi::OpenAPI::TypeMapper.map(_Array(String))
    assert_equal "array", result[:type]
    assert_equal({type: "string"}, result[:items])
  end

  def test_unknown_type_falls_back_to_string
    fake = Class.new
    assert_equal({type: "string"}, AnotherApi::OpenAPI::TypeMapper.map(fake))
  end

  def test_nilable_of_nilable_uniqs_the_null_into_existing_array
    # _Nilable(_Nilable(String)) — the outer wrapping sees inner[:type] already
    # an Array, must merge "null" into it without duplicating.
    inner = Literal::Types::NilableType.new(String)
    outer = Literal::Types::NilableType.new(inner)

    result = AnotherApi::OpenAPI::TypeMapper.map(outer)
    assert_equal ["string", "null"], result[:type]
  end
end
