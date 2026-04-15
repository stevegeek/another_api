module ApiQueryLanguage
  module Errors
    class UnexpectedNodeTypeError < Error
      def initialize(visitor, node)
        super("Unsupported node type: #{node.class.name} in #{visitor.class.name} visitor.")
      end
    end
  end
end
