require "test_helper"

module ApiQueryLanguage
  module Filtering
    class ExpressionParserTest < ::ApiQueryLanguageTestCase
      def setup
        @parser = ExpressionParser.new
      end

      def test_field_token
        result = @parser.parse!("my_field{lte}:1")
        assert_pattern do
          result => Nodes::Root(
            node: Nodes::Conditions(
              nodes: [
                Nodes::FieldComparison(
                  field: "my_field",
                  comparison: "lte",
                  value: Nodes::ValueExpression(nodes: [Nodes::Value(value: "1")])
                )
              ]
            )
          )
        end
      end

      def test_wildcard_value
        result = @parser.parse!("my_field:foo*")
        assert_pattern do
          result => Nodes::Root(
            node: Nodes::Conditions(
              nodes: [
                Nodes::Field(
                  field: "my_field",
                  value: Nodes::ValueExpression(nodes: [Nodes::ValueWithWildcard(parts: ["foo", "*"])])
                )
              ]
            )
          )
        end
      end

      def test_and_conditions_expression
        result = @parser.parse!("my_field:1 [and] another_field:foo%20bee [or] last_field{gte}:10")
        assert_pattern do
          result => Nodes::Root(
            node: Nodes::ConditionsAnd(
              nodes: [
                Nodes::Field(
                  field: "my_field",
                  value: Nodes::ValueExpression(nodes: [Nodes::Value(value: "1")])
                ),
                Nodes::ConditionsOr(
                  nodes: [
                    Nodes::Field(
                      field: "another_field",
                      value: Nodes::ValueExpression(nodes: [Nodes::Value(value: "foo%20bee")])
                    ),
                    Nodes::Conditions(
                      nodes: [
                        Nodes::FieldComparison(
                          field: "last_field",
                          comparison: "gte",
                          value: Nodes::ValueExpression(nodes: [Nodes::Value(value: "10")])
                        )
                      ]
                    )
                  ]
                )
              ]
            )
          )
        end
      end

      def test_complex_expression
        result = @parser.parse!("(my_field: 1 | 10 [and] another_field{gt}: foo%20bee [or] last_field: bar) [and] wow:hello [or] (foo:bar [and] baz:qux|quoo) [and] tags:t1&t2&t3")
        assert_pattern do
          result => Nodes::Root(
            node: Nodes::ConditionsAnd(
              nodes: [
                Nodes::ConditionsGroup(
                  nodes: [
                    Nodes::ConditionsAnd(
                      nodes: [
                        Nodes::Field(
                          field: "my_field",
                          value: Nodes::ValueExpressionOr(nodes: [Nodes::Value(value: "1"), Nodes::ValueExpression(nodes: [Nodes::Value(value: "10")])])
                        ),
                        Nodes::ConditionsOr(
                          nodes: [
                            Nodes::FieldComparison(
                              field: "another_field",
                              comparison: "gt",
                              value: Nodes::ValueExpression(nodes: [Nodes::Value(value: "foo%20bee")])
                            ),
                            Nodes::Conditions(
                              nodes: [
                                Nodes::Field(
                                  field: "last_field",
                                  value: Nodes::ValueExpression(nodes: [Nodes::Value(value: "bar")])
                                )
                              ]
                            )
                          ]
                        )
                      ]
                    )
                  ]
                ),
                Nodes::ConditionsOr(
                  nodes: [
                    Nodes::Field(
                      field: "wow",
                      value: Nodes::ValueExpression(nodes: [Nodes::Value(value: "hello")])
                    ),
                    Nodes::ConditionsAnd(
                      nodes: [
                        Nodes::ConditionsGroup(
                          nodes: [
                            Nodes::ConditionsAnd(
                              nodes: [
                                Nodes::Field(
                                  field: "foo",
                                  value: Nodes::ValueExpression(nodes: [Nodes::Value(value: "bar")])
                                ),
                                Nodes::Conditions(
                                  nodes: [
                                    Nodes::Field(
                                      field: "baz",
                                      value: Nodes::ValueExpressionOr(
                                        nodes: [
                                          Nodes::Value(value: "qux"),
                                          Nodes::ValueExpression(nodes: [Nodes::Value(value: "quoo")])
                                        ]
                                      )
                                    )
                                  ]
                                )
                              ]
                            )
                          ]
                        ),
                        Nodes::Conditions(
                          nodes: [
                            Nodes::Field(
                              field: "tags",
                              value: Nodes::ValueExpressionAnd(
                                nodes: [
                                  Nodes::Value(value: "t1"),
                                  Nodes::ValueExpressionAnd(
                                    nodes: [
                                      Nodes::Value(value: "t2"),
                                      Nodes::ValueExpression(nodes: [Nodes::Value(value: "t3")])
                                    ]
                                  )
                                ]
                              )
                            )
                          ]
                        )
                      ]
                    )
                  ]
                )
              ]
            )
          )
        end
      end
    end
  end
end
