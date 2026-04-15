# frozen_string_literal: true

require_relative "api_query_language/version"

module ApiQueryLanguage
  module Filtering
    module Nodes; end
    module Fields; end
  end

  module Sorting
    module Nodes; end
  end
end

require_relative "api_query_language/errors/error"
require_relative "api_query_language/errors/invalid_expression_error"
require_relative "api_query_language/errors/invalid_field_error"
require_relative "api_query_language/errors/invalid_field_value_error"
require_relative "api_query_language/errors/disallowed_value_error"
require_relative "api_query_language/errors/unexpected_node_type_error"
require_relative "api_query_language/errors/unsupported_field_type_error"
require_relative "api_query_language/errors/unsupported_collection_field_type_error"

require_relative "api_query_language/expression_parser_helper"

require_relative "api_query_language/filtering/nodes/conditions"
require_relative "api_query_language/filtering/nodes/conditions_and"
require_relative "api_query_language/filtering/nodes/conditions_group"
require_relative "api_query_language/filtering/nodes/conditions_not"
require_relative "api_query_language/filtering/nodes/conditions_or"
require_relative "api_query_language/filtering/nodes/field"
require_relative "api_query_language/filtering/nodes/field_comparison"
require_relative "api_query_language/filtering/nodes/root"
require_relative "api_query_language/filtering/nodes/value"
require_relative "api_query_language/filtering/nodes/value_expression"
require_relative "api_query_language/filtering/nodes/value_expression_and"
require_relative "api_query_language/filtering/nodes/value_expression_or"
require_relative "api_query_language/filtering/nodes/value_with_wildcard"

require_relative "api_query_language/filtering/fields/filter_value_caster"
require_relative "api_query_language/filtering/filter_parser_helper"
require_relative "api_query_language/filtering/expression_lexer.rex"
require_relative "api_query_language/filtering/expression_parser.y"
require_relative "api_query_language/filtering/filter_expression"

require_relative "api_query_language/sorting/nodes/field_sort"
require_relative "api_query_language/sorting/sort_parser_helper"
require_relative "api_query_language/sorting/expression_lexer.rex"
require_relative "api_query_language/sorting/expression_parser.y"
require_relative "api_query_language/sorting/sort_expression"
