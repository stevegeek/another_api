require "uri"

module ApiQueryLanguage
  module ExpressionParserHelper
    def lexer
      raise NoMethodError, "You must implement a lexer method that returns an instance of ExpressionLexer"
    end

    # Delegate to lexer for tokens
    def next_token
      lexer.next_token
    end

    def current_string
      return unless lexer.ss
      lexer.ss.string[lexer.ss.pos..]
    end

    def parse_error_context
      " at position #{lexer.ss.pos + 1}"
    end

    def parse_error_reason
      if current_string
        " the following cannot be parsed '#{current_string}'.#{parse_error_context}"
      else
        " it is not a valid query expression."
      end
    end

    def parse!(str)
      validate_expression!(str)
      lexer.parse(str, self) # This then calls the do_parse method on the parser
    rescue Racc::ParseError, Filtering::ExpressionLexer::LexerError, Sorting::ExpressionLexer::LexerError
      raise Errors::InvalidExpressionError.new(str, parse_error_reason)
    end

    def validate_expression!(str)
      raise Errors::InvalidExpressionError.new(str, "it is not a string") unless str.is_a?(String)
      raise Errors::InvalidExpressionError.new(str, "it is blank") if str.nil? || str.empty?
      raise Errors::InvalidExpressionError.new(str, "it is too long") if str.length > 1000
    end
  end
end
