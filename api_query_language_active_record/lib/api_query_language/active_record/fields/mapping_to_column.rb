module ApiQueryLanguage
  module ActiveRecord
    module Fields
      class MappingToColumn
        Mapping = Data.define(:column, :relation, :value_transform, :allowed_values) do
          def initialize(column:, relation:, value_transform: nil, allowed_values: nil)
            super
          end
        end
        ColumnInfo = Data.define(:associations, :model, :field_name)

        def initialize(root_model, current_relation, field_to_attribute_mappings)
          @current_relation = current_relation
          @root_model = root_model
          @field_to_attribute_mappings = field_to_attribute_mappings
        end

        def map_field(field)
          raw_mapping = @field_to_attribute_mappings[field.to_sym]
          value_transform = raw_mapping.respond_to?(:transform) ? raw_mapping.transform : nil
          allowed_values = raw_mapping.respond_to?(:allowed_values) ? raw_mapping.allowed_values : nil

          column_info = table_column_for_field!(fetch_field_mapping!(field))
          relation = @current_relation
          if column_info.is_a?(ColumnInfo)
            result = apply_joins!(column_info, relation)
            Mapping.new(column: result.column, relation: result.relation, value_transform:, allowed_values:)
          else
            Mapping.new(column: @root_model.arel_table[column_info], relation:, value_transform:, allowed_values:)
          end
        end

        private

        def apply_joins!(column_info, relation)
          associations_map = {}
          column_info.associations.reduce(associations_map) do |map, association|
            map[association] = {}
            map[association]
          end
          relation = relation.joins(associations_map).distinct
          column = column_info.model.arel_table[column_info.field_name]
          Mapping.new(column:, relation:)
        end

        # Get the column from the field identifier
        def table_column_for_field!(field)
          field = field.to_s
          # If a '.' appears in the field name then this is a joined field, access the model from the association
          # If no '.' appears then this is a field on the current model, so just use root_relation
          if field&.include?(".")
            nested_path = field.split(".")
            associations = nested_path[0..-2]
            field_name = nested_path.last
            target_model = associations.reduce(@root_model) do |model, attribute|
              association = model.reflect_on_association(attribute.to_sym)
              raise ::ApiQueryLanguage::Errors::InvalidFieldValueError.new("association", attribute) unless association
              association.klass
            end

            ColumnInfo.new(associations:, model: target_model, field_name:)
          else
            field
          end
        end

        def fetch_field_mapping!(name)
          name_sym = name.to_sym
          raise ::ApiQueryLanguage::Errors::InvalidFieldError.new(name_sym) unless @field_to_attribute_mappings.key?(name_sym)
          raw = @field_to_attribute_mappings[name_sym]

          # Rich mapping (e.g. QueryableConfig) — extract the column
          if raw.respond_to?(:column)
            raw.column || name_sym
          else
            # Simple mapping: String, Symbol, nil, or Array
            mapping = raw.tap do |m|
              break name_sym if m.nil?
              raise ::ApiQueryLanguage::Errors::InvalidFieldError.new(name_sym) if (m.respond_to?(:empty?) && m.empty?) || (m.is_a?(Array) && m.size != 1)
            end
            mapping.is_a?(Array) ? mapping.first : mapping
          end
        end
      end
    end
  end
end
