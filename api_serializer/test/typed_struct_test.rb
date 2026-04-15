require "test_helper"

class ApiSerializer::TypedStructTest < ApiSerializerTestCase
  class Point < ApiSerializer::TypedStruct
    attribute :x, _Nilable(_Integer)
    attribute :y, _Nilable(_Integer)
  end

  class OtherPoint < ApiSerializer::TypedStruct
    attribute :x, _Nilable(_Integer)
    attribute :y, _Nilable(_Integer)
  end

  test "inspect includes class name and attributes" do
    assert_equal "#<ApiSerializer::TypedStructTest::Point x: 1, y: 2>", Point.new(x: 1, y: 2).inspect
  end

  test "merge combines attributes preferring the right side" do
    merged = Point.new(x: 1, y: 2).merge(Point.new(x: 9, y: 10))
    assert_equal 9, merged.x
    assert_equal 10, merged.y
  end

  test "merge with ignore_nils preserves left values when right values are nil" do
    merged = Point.new(x: 1, y: 2).merge(Point.new(x: nil, y: 99), ignore_nils: true)
    assert_equal 1, merged.x
    assert_equal 99, merged.y
  end

  test "merge raises when other is not a TypedStruct" do
    assert_raises(ArgumentError) { Point.new(x: 1, y: 2).merge({x: 5}) }
  end

  # Equality is delegated to Literal::Properties (prepended), which compares by
  # class identity and attribute values — exactly the behaviour we want.
  test "equality compares by class and attributes" do
    assert_equal Point.new(x: 1, y: 2), Point.new(x: 1, y: 2)
    refute_equal Point.new(x: 1, y: 2), Point.new(x: 1, y: 3)
    refute_equal Point.new(x: 1, y: 2), OtherPoint.new(x: 1, y: 2)
  end
end
