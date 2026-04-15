module ApiQueryLanguage
  NodeWithContext = Data.define(:node, :current_relation, :context) do
    def deconstruct
      [node, current_relation, context]
    end
  end
end
