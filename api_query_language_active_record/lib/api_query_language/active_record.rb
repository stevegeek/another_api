# frozen_string_literal: true

require "active_record"
require "api_query_language"

module ApiQueryLanguage
  module ActiveRecord
    module Filtering
      module Visitors; end
    end

    module Sorting
      module Visitors; end
    end

    module Fields; end
  end
end

require_relative "active_record/node_with_context"
require_relative "active_record/query_context"
require_relative "active_record/visitor"
require_relative "active_record/fields/mapping_to_column"

require_relative "active_record/filtering/visitors/field_visitor"
require_relative "active_record/filtering/visitors/field_comparison_visitor"
require_relative "active_record/filtering/visitors/conditions_visitor"
require_relative "active_record/filtering/visitors/conditions_and_visitor"
require_relative "active_record/filtering/visitors/conditions_group_visitor"
require_relative "active_record/filtering/visitors/conditions_not_visitor"
require_relative "active_record/filtering/visitors/conditions_or_visitor"
require_relative "active_record/filtering/visitors/root_visitor"
require_relative "active_record/filtering/visitors/value_expression_visitor"
require_relative "active_record/filtering/visitors/value_expression_and_visitor"
require_relative "active_record/filtering/visitors/value_expression_or_visitor"
require_relative "active_record/filtering/visitors/value_visitor"
require_relative "active_record/filtering/visitors/value_with_wildcard_visitor"
require_relative "active_record/filtering/visitors/ast_visitor"

require_relative "active_record/sorting/visitors/field_sort_visitor"

require_relative "active_record/filtering/filter_expression"
require_relative "active_record/sorting/sort_expression"
