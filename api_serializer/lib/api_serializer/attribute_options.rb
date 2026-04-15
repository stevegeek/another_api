module ApiSerializer
  class AttributeOptions
    def initialize(attribute_reflection, from_path:, composed_of:, decompose_to:, convert_by:, virtual:, queryable: nil, nested_schema: nil)
      @attribute_reflection = attribute_reflection
      @from_path = from_path
      @composed_of = composed_of
      @decompose_to = decompose_to
      @convert_by = convert_by
      @virtual = virtual
      @nested_schema = nested_schema

      config = queryable ? normalize_queryable(queryable) : QueryableConfig.new(filter: false, sort: false)
      @filterable = config.filterable?
      @sortable = config.sortable?
      @query_column = config.column
      @query_transform = config.transform
      @allowed_values = config.allowed_values
    end

    def name = @attribute_reflection.name
    def type = @attribute_reflection.type
    def reader = @attribute_reflection.reader
    def positional = @attribute_reflection.positional
    def default = @attribute_reflection.default
    def coercion = @attribute_reflection.coercion

    attr_reader :from_path, :composed_of, :decompose_to, :convert_by, :virtual, :nested_schema,
      :query_column, :query_transform, :allowed_values

    def compose? = !!composed_of
    def decompose? = !!decompose_to
    def virtual? = !!virtual
    def filterable? = !!@filterable
    def sortable? = !!@sortable
    def association? = !!@nested_schema

    def to_h
      {
        name:, type:, reader:, positional:, default:,
        composed_of:, decompose_to:, convert_by:, from_path:, virtual:,
        filterable: @filterable,
        sortable: @sortable,
        query_column: @query_column,
        query_transform: @query_transform,
        allowed_values: @allowed_values,
        nested_schema: @nested_schema
      }
    end

    private

    def normalize_queryable(value)
      case value
      when true then QueryableConfig.new
      when Hash then QueryableConfig.new(**value)
      when QueryableConfig then value
      else raise ArgumentError, "queryable: must be true or a Hash, got #{value.class}"
      end
    end
  end
end
