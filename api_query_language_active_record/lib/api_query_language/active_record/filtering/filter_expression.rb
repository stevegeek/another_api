module ApiQueryLanguage
  module ActiveRecord
    module Filtering
      class FilterExpression < ::ApiQueryLanguage::Filtering::FilterExpression
        def apply_to(query)
          # unscoped avoids merging any default_scope from the model; the
          # caller's relation supplies its own scoping and we only add WHERE.
          filter_query = build_filter_query(query.model.unscoped)
          query.merge(filter_query)
        end

        private

        def build_filter_query(root_relation)
          context = ::ApiQueryLanguage::QueryContext.new(root_relation, field_to_attribute_mappings)
          Visitors::AstVisitor.new(context).walk(ast_root)
        end
      end
    end
  end
end
