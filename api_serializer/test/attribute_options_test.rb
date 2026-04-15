require "test_helper"

class ApiSerializer::AttributeOptionsTest < ApiSerializerTestCase
  Reflection = Struct.new(:name, :type, :reader, :positional, :default, :coercion)

  def make(queryable: nil)
    ApiSerializer::AttributeOptions.new(
      Reflection.new(:foo, String, :public, false, nil, nil),
      from_path: nil, composed_of: nil, decompose_to: nil,
      convert_by: nil, virtual: false, queryable: queryable
    )
  end

  test "to_h returns a hash containing every defined option" do
    h = make.to_h
    assert_equal :foo, h[:name]
    assert_equal String, h[:type]
    assert_equal :public, h[:reader]
    assert_equal false, h[:filterable]
    assert_equal false, h[:sortable]
    refute h[:virtual]
  end

  test "queryable: accepts an existing QueryableConfig instance" do
    cfg = ApiSerializer::QueryableConfig.new(filter: true, sort: false)
    options = make(queryable: cfg)
    assert options.filterable?
    refute options.sortable?
  end

  test "queryable: raises ArgumentError when given an unsupported value" do
    err = assert_raises(ArgumentError) { make(queryable: 42) }
    assert_match(/queryable: must be true or a Hash/, err.message)
  end
end
