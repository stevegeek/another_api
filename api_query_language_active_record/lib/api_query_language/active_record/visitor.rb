module ApiQueryLanguage
  module ActiveRecord
    class Visitor
      def initialize(query_context)
        @root_relation = query_context.root_relation
        @field_to_attribute_mappings = query_context.field_to_attribute_mappings
      end

      def visit(node_with_context)
        raise "Not implemented"
      end

      private

      attr_reader :root_relation, :field_to_attribute_mappings

      def mapping_to_column(current_relation)
        ApiQueryLanguage::ActiveRecord::Fields::MappingToColumn.new(
          root_model,
          current_relation,
          field_to_attribute_mappings
        )
      end

      def unscoped_root_relation
        @unscoped_root_relation ||= root_relation.unscoped
      end

      def arel_table
        @arel_table ||= root_model.arel_table
      end

      def root_model
        @root_model ||= root_relation.model
      end
    end
  end
end
