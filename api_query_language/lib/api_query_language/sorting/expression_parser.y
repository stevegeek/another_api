# Regenerate with `bundle exec rake generate` from api_query_language/.

class ApiQueryLanguage::Sorting::ExpressionParser < Racc::Parser
start
  expression

options
  no_result_var

rule
  expression
    : sorts

  sorts
    : sort SORT_SEPARATOR expression                               { parse_join_sort_expression(val) }
    | sort                                                         { parse_single_sort_expression(val) }

  sort
    : field_expression DIRECTION_OPERATOR                          { parse_field_sort(val) }

  field_expression
    : fields

  fields
    : FIELD_IDENTIFIER FIELD_IDENTIFIER_SEPARATOR field_expression { parse_field(val) }
    | FIELD_IDENTIFIER                                             { parse_field(val) }

end # End of grammar

---- inner
  include ApiQueryLanguage::ExpressionParserHelper
  include ApiQueryLanguage::Sorting::SortParserHelper
