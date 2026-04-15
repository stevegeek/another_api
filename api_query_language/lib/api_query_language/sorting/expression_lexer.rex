# Regenerate with `bundle exec rake generate` from api_query_language/.

class ApiQueryLanguage::Sorting::ExpressionLexer
macros
  FIELD_IDENTIFIER    /[A-Za-z][0-9A-Za-z_\-]+/
  DIRECTION_OPERATOR  /asc|desc/

# options
#   debug

rules
  /#{FIELD_IDENTIFIER}/      { [:FIELD_IDENTIFIER, text] }
  /:(#{DIRECTION_OPERATOR})/ { [:DIRECTION_OPERATOR, matches[0]] }
  /\./                       { [:FIELD_IDENTIFIER_SEPARATOR, text] }
  /;/                        { [:SORT_SEPARATOR, text] }
  /\s+/                      # Ignoring whitespace

inner

  def parse(str, parser)
    self.ss = scanner_class.new str
    self.state ||= nil

    # Call the parser to do the work
    parser.do_parse
  end

end
