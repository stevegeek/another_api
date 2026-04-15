require "test_helper"

class ApiSerializer::TargetDataStructureTest < ApiSerializerTestCase
  class Inner < ApiSerializer::TargetDataStructure
    attribute :v, _Nilable(_Integer)
  end

  class Outer < ApiSerializer::TargetDataStructure
    attribute :name, _Nilable(_String)
    attribute :nested, _Nilable(_Any)
    attribute :nested_collection, _Nilable(_Any)
  end

  test "as_json returns a plain hash for primitive attributes" do
    assert_equal(
      {name: "ok", nested: nil, nested_collection: nil},
      Outer.new(name: "ok", nested: nil, nested_collection: nil).as_json
    )
  end

  test "as_json recursively converts nested TargetDataStructure values" do
    out = Outer.new(name: "wrap", nested: Inner.new(v: 7), nested_collection: nil)
    assert_equal({name: "wrap", nested: {v: 7}, nested_collection: nil}, out.as_json)
  end

  test "as_json recursively converts arrays of nested structs" do
    out = Outer.new(name: "wrap", nested: nil, nested_collection: [Inner.new(v: 1), Inner.new(v: 2)])
    assert_equal([{v: 1}, {v: 2}], out.as_json[:nested_collection])
  end

  test "as_json leaves arrays of primitives alone" do
    out = Outer.new(name: "wrap", nested: nil, nested_collection: [1, 2, "three"])
    assert_equal([1, 2, "three"], out.as_json[:nested_collection])
  end

  test "as_json accepts (and ignores) an options arg for Ruby convention compatibility" do
    result = Outer.new(name: "x", nested: nil, nested_collection: nil).as_json({only: :name})
    assert_equal({name: "x", nested: nil, nested_collection: nil}, result)
  end
end
