module ApiQueryLanguage
  module ActiveRecord
    module Sorting
      class SortExpression < ::ApiQueryLanguage::Sorting::SortExpression
        def apply_to(query)
          # unscoped avoids merging any default_scope from the model; the
          # caller's relation supplies its own scoping and we only add ORDER.
          sort_query = build_sorted_query(query.model.unscoped)
          query.merge(sort_query)
        end

        private

        def build_sorted_query(root_relation)
          context = ::ApiQueryLanguage::QueryContext.new(root_relation, field_to_attribute_mappings)
          Visitors::FieldSortVisitor.new(context).walk(parsed)
        end
      end
    end
  end
end
