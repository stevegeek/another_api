class ApiQueryLanguage::Filtering::ExpressionLexer
macros
  FIELD_NAME           /[A-Za-z][0-9A-Za-z_\-.]+/
  COMPARISON_OPERATOR  /eq|ieq|neq|gt|gte|lt|lte/
  WILDCARD             /[*+]/
  # https://documentation.mapp.com/1.0/en/url-encoding-and-what-characters-are-valid-in-a-uri-36147771.html
  # The set of valid characters is [A-Za-z0-9\-_.~], some symbols are reserved for special meaning so
  # must be encoded, and all other characters must be encoded too.
  URL_ENCODED_VALUE    /(?:[A-Za-z0-9\-_.~]|%[0-9A-Fa-f]{2})+/ # URL encoded value

# options
#   debug

rules
  /(#{FIELD_NAME})\{(#{COMPARISON_OPERATOR})\}:/ { [:FIELD_WITH_COMPARISON_OP, matches] }
  /(#{FIELD_NAME}):/                             { [:FIELD, matches[0]] }
  /null\((#{FIELD_NAME})\)/                      { [:NULL_FIELD, matches[0]] }
  /NULL\((#{FIELD_NAME})\)/                      { [:NULL_FIELD, matches[0]] }
  /#{URL_ENCODED_VALUE}/                         { [:ENCODED_VALUE, text] }
  /\[and\]/i                                     { [:AND_CONDITION, text] }
  /\[or\]/i                                      { [:OR_CONDITION, text] }
  /\[not\]/i                                     { [:NOT_CONDITION, text] }
  /\(/                                           { [:GROUP_START, text] }
  /\)/                                           { [:GROUP_END, text] }
  /\|/                                           { [:VALUE_OR, text] }
  /\&/                                           { [:VALUE_AND, text] }
  /#{WILDCARD}/                                  { [:VALUE_WILDCARD, text] }
  /\s+/                                          # Ignoring whitespace

inner

  # override the default parse method
  def parse(str, parser)
    self.ss = scanner_class.new str
    self.state ||= nil

    # Call the parser to do the work
    parser.do_parse
  end

end
