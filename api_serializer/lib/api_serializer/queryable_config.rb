module ApiSerializer
  QueryableConfig = Data.define(:filter, :sort, :column, :transform, :allowed_values) do
    def initialize(filter: true, sort: true, column: nil, transform: nil, allowed_values: nil)
      super
    end

    def filterable? = !!filter
    def sortable? = !!sort
  end
end
