# frozen_string_literal: true

require "test_helper"

class ApiSerializer::DataTransformerTest < ApiSerializerTestCase
  class TestTargetDataStructure < ApiSerializer::TargetDataStructure
    attribute :name, String
    attribute :age, Integer
    attribute :email, _Nilable(String), from_path: "contact.email"

    # If the attribute doesnt appear in the data, then the callables are not called at all
    attribute :full_name, _Nilable(String), composed_of: %w[first_name last_name], convert_by: ->(first_name, last_name) { "#{first_name.upcase} #{last_name}" }
    attribute :first_initial, _Nilable(String), from_path: "initials", decompose_to: [:first_initial, :last_initial], convert_by: ->(initials) { initials.chars }
    attribute :last_initial, _Nilable(String), from_path: "initials", decompose_to: [:first_initial, :last_initial], convert_by: ->(initials) { initials.chars }

    # If the attribute doesnt appear in the data, then the callables are still called, so need to handle nils
    attribute :parsed_data, _Nilable(String), convert_by: ->(data) { data&.tr("1", "2") }, from_path: "raw_data"
    attribute :greeting, _Nilable(String), convert_by: ->(data, context) { "Hello, #{data[:name]}! You are #{context[:language]}" if data[:name] }
  end

  setup do
    @target_data_structure = TestTargetDataStructure
    @transformer = ApiSerializer::DataTransformer.new(@target_data_structure)
    @min_data = {name: "John Doe", age: 30}
  end

  test "initialize raises error when target data structure has no attributes" do
    empty_structure = Class.new(ApiSerializer::TargetDataStructure)
    assert_raises(ApiSerializer::Errors::VariantDefinitionError) do
      ApiSerializer::DataTransformer.new(empty_structure)
    end
  end

  test "transform basic attributes" do
    result = @transformer.transform(@min_data)
    assert_equal "John Doe", result.name
    assert_equal 30, result.age
  end

  test "transform attribute with from_path" do
    data = @min_data.merge(contact: {email: "john@example.com"})
    result = @transformer.transform(data)
    assert_equal "john@example.com", result.email
  end

  test "transform attribute with composition" do
    data = @min_data.merge(first_name: "John", last_name: "Doe")
    result = @transformer.transform(data)
    assert_equal "JOHN Doe", result.full_name
  end

  test "transform attribute with convert_by and context" do
    context = {language: "English"}
    result = @transformer.transform(@min_data, context)
    assert_equal "Hello, John Doe! You are English", result.greeting
  end

  test "transform attribute with convert_by and from_path" do
    data = @min_data.merge(raw_data: "Some raw 1")
    result = @transformer.transform(data)
    assert_equal "Some raw 2", result.parsed_data
  end

  test "transform attribute with decomposition" do
    data = @min_data.merge(initials: "JD")
    result = @transformer.transform(data)
    assert_equal "J", result.first_initial
    assert_equal "D", result.last_initial
  end

  test "transform raises DataTransformError when data doesn't match schema" do
    data = {name: "John Doe", age: "thirty"}
    assert_raises(ApiSerializer::Errors::DataTransformError) do
      @transformer.transform(data)
    end
  end

  test "inspect returns a string representation" do
    assert_match(/#<ApiSerializer::DataTransformer/, @transformer.inspect)
  end

  test "equality" do
    other_transformer = ApiSerializer::DataTransformer.new(@target_data_structure)
    assert_equal @transformer, other_transformer

    different_structure = Class.new(ApiSerializer::TargetDataStructure) do
      attribute :different, String
    end
    different_transformer = ApiSerializer::DataTransformer.new(different_structure)
    refute_equal @transformer, different_transformer
  end

  # Composed callable accepts an optional trailing context arg (arity == argc + 1).
  class TargetWithComposedContext < ApiSerializer::TargetDataStructure
    attribute :full_name, _Nilable(String),
      composed_of: %w[first last],
      convert_by: ->(first, last, context) { "#{first} #{last}/#{context[:greet]}" }
  end

  test "composed convert_by callable receives the context as a trailing argument" do
    transformer = ApiSerializer::DataTransformer.new(TargetWithComposedContext)
    result = transformer.transform({first: "Ada", last: "Lovelace"}, {greet: "hi"})
    assert_equal "Ada Lovelace/hi", result.full_name
  end

  # Composed callable arity that doesn't match argc or argc+1 → AttributeDefinitionError.
  class TargetWithBadComposedArity < ApiSerializer::TargetDataStructure
    attribute :foo, _Nilable(String),
      composed_of: %w[a b],
      convert_by: ->(_a, _b, _c, _d, _e) { "x" }
  end

  test "composed convert_by with wrong arity raises AttributeDefinitionError" do
    transformer = ApiSerializer::DataTransformer.new(TargetWithBadComposedArity)
    assert_raises(ApiSerializer::Errors::AttributeDefinitionError) do
      transformer.transform({a: "1", b: "2"})
    end
  end

  # Single-value callable arity != 1 and != 2 → AttributeDefinitionError.
  class TargetWithBadSimpleArity < ApiSerializer::TargetDataStructure
    attribute :foo, _Nilable(String),
      from_path: "src",
      convert_by: ->(_a, _b, _c) { "x" }
  end

  test "single-value convert_by with wrong arity raises AttributeDefinitionError" do
    transformer = ApiSerializer::DataTransformer.new(TargetWithBadSimpleArity)
    assert_raises(ApiSerializer::Errors::AttributeDefinitionError) do
      transformer.transform({src: "v"})
    end
  end

  # Object-source path: when the data isn't a Hash, attribute extraction goes via
  # call_getter, which uses Object#method(name).arity == 0 to decide whether to invoke.
  class TargetForGetter < ApiSerializer::TargetDataStructure
    attribute :name, String
    attribute :age, Integer
  end

  test "transform reads attributes from objects via zero-arity getter methods" do
    object = Struct.new(:name, :age).new("Bea", 41)
    transformer = ApiSerializer::DataTransformer.new(TargetForGetter)
    result = transformer.transform(object)
    assert_equal "Bea", result.name
    assert_equal 41, result.age
  end
end
