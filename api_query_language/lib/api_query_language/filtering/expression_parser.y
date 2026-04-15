class ApiQueryLanguage::Filtering::ExpressionParser < Racc::Parser
prechigh
  left     AND_CONDITION VALUE_AND
  left     OR_CONDITION VALUE_OR
preclow

start
  query

options
  no_result_var

rule
  query
    : expression                                   { parse_query(val) }

  expression
    : conditions

  conditions
    : condition AND_CONDITION expression           { parse_conditions_and(val) }
    | condition OR_CONDITION expression            { parse_conditions_or(val) }
    | NOT_CONDITION condition                      { parse_condition_not(val) }
    | condition                                    { parse_condition(val) }

  condition
    : GROUP_START conditions GROUP_END             { parse_conditions_group(val) }
    | FIELD_WITH_COMPARISON_OP ENCODED_VALUE       { parse_condition_field_with_comparison(val) }
    | FIELD value_expression                       { parse_condition_field(val) }
    | NULL_FIELD                                   { parse_condition_null_field(val) }

  value_expression
    : encoded_value VALUE_OR value_expression      { parse_value_expression_or(val) }
    | encoded_value VALUE_AND value_expression     { parse_value_expression_and(val) }
    | encoded_value                                { parse_value_expression(val) }

  encoded_value
    : ENCODED_VALUE                                { parse_encoded_value(val) }
    | VALUE_WILDCARD ENCODED_VALUE                 { parse_encoded_value_wildcard(val) }
    | ENCODED_VALUE VALUE_WILDCARD                 { parse_encoded_value_wildcard(val) }
    | VALUE_WILDCARD ENCODED_VALUE VALUE_WILDCARD  { parse_encoded_value_wildcard(val) }

end # End of grammar

---- inner
  include ApiQueryLanguage::ExpressionParserHelper
  include ApiQueryLanguage::Filtering::FilterParserHelper
