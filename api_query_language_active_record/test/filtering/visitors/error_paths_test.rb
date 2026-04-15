require "test_helper"

# Coverage for defensive error paths in the visitors. These errors can't be
# triggered through the public parse → apply pipeline because the parser only
# produces well-formed AST nodes — they exist as guards for misuse (e.g.
# building a NodeWithContext by hand with the wrong node class) or for column
# types the visitor doesn't know how to handle.
module ApiQueryLanguage
  module Filtering
    module Visitors
      class ErrorPathsTest < ::ApiQueryLanguageTestCase
        include TestInTempDatabase

        def make_visitor(klass, relation: TestInTempDatabase::TestUserModel.all, mappings: {name: "name"})
          klass.new(::ApiQueryLanguage::QueryContext.new(
            root_relation: relation,
            field_to_attribute_mappings: mappings
          ))
        end

        # ----------------------------------------------------------------
        # UnexpectedNodeTypeError — guard fires when a visitor receives the
        # wrong node class.
        # ----------------------------------------------------------------

        def test_value_visitor_rejects_non_value_node
          err = assert_raises(Errors::UnexpectedNodeTypeError) do
            make_visitor(::ApiQueryLanguage::ActiveRecord::Filtering::Visitors::ValueVisitor).send(
              :extract_value,
              Nodes::ValueWithWildcard.new(parts: ["*", "x"])
            )
          end
          assert_match(/Unsupported node type/, err.message)
          assert_match(/ApiQueryLanguage::ActiveRecord::Filtering::Visitors::ValueVisitor/, err.message)
        end

        def test_value_with_wildcard_visitor_rejects_non_wildcard_node
          err = assert_raises(Errors::UnexpectedNodeTypeError) do
            make_visitor(::ApiQueryLanguage::ActiveRecord::Filtering::Visitors::ValueWithWildcardVisitor).send(
              :extract_value,
              Nodes::Value.new(value: "x")
            )
          end
          assert_match(/Unsupported node type/, err.message)
          assert_match(/ApiQueryLanguage::ActiveRecord::Filtering::Visitors::ValueWithWildcardVisitor/, err.message)
        end

        def test_field_comparison_visitor_rejects_non_value_node
          # FieldComparison node carrying a ValueExpression whose inner node
          # is a ValueWithWildcard rather than a Value — visit() should reject.
          relation = TestInTempDatabase::TestUserModel.all
          context = NodeWithContext.new(
            node: Nodes::FieldComparison.new(
              field: "name",
              comparison: "eq",
              value: Nodes::ValueExpression.new(
                nodes: [Nodes::ValueWithWildcard.new(parts: ["*", "x"])]
              )
            ),
            current_relation: relation,
            context: nil
          )
          err = assert_raises(Errors::UnexpectedNodeTypeError) do
            make_visitor(::ApiQueryLanguage::ActiveRecord::Filtering::Visitors::FieldComparisonVisitor).visit(context)
          end
          assert_match(/ApiQueryLanguage::ActiveRecord::Filtering::Visitors::FieldComparisonVisitor/, err.message)
        end

        # ----------------------------------------------------------------
        # UnsupportedCollectionFieldTypeError — fires when a column's caster
        # responds to :subtype (i.e. is a collection) but isn't a PG array.
        # The natural trigger is a PG range column.
        # ----------------------------------------------------------------

        def test_value_visitor_rejects_unsupported_collection_type
          omit_when_no_pg!

          # Add a daterange column for the duration of this test — the
          # surrounding test transaction rolls it back.
          conn = ::ActiveRecord::Base.connection
          conn.execute "ALTER TABLE aql_test_users ADD COLUMN active_period daterange"
          TestInTempDatabase::TestUserModel.reset_column_information

          arel_column = TestInTempDatabase::TestUserModel.arel_table[:active_period]
          context = NodeWithContext.new(
            node: Nodes::Value.new(value: "2020-01-01"),
            current_relation: TestInTempDatabase::TestUserModel.all,
            context: arel_column
          )
          err = assert_raises(Errors::UnsupportedCollectionFieldTypeError) do
            make_visitor(::ApiQueryLanguage::ActiveRecord::Filtering::Visitors::ValueVisitor).visit(context)
          end
          assert_match(/Unsupported collection type/, err.message)
        ensure
          TestInTempDatabase::TestUserModel.reset_column_information
        end
      end
    end
  end
end

# ----------------------------------------------------------------
# Same defensive guard in the sorting ::ApiQueryLanguage::ActiveRecord::Sorting::Visitors::FieldSortVisitor.
# ----------------------------------------------------------------

module ApiQueryLanguage
  module Sorting
    module Visitors
      class FieldSortVisitorErrorTest < ::ApiQueryLanguageTestCase
        include TestInTempDatabase

        def test_field_sort_visitor_rejects_non_field_sort_node
          # Public entry point is `walk(nodes)`, which iterates and calls the
          # private `visit`. Pass a non-FieldSort node to trigger the guard.
          visitor = ::ApiQueryLanguage::ActiveRecord::Sorting::Visitors::FieldSortVisitor.new(::ApiQueryLanguage::QueryContext.new(
            root_relation: TestInTempDatabase::TestUserModel.all,
            field_to_attribute_mappings: {}
          ))
          err = assert_raises(ApiQueryLanguage::Errors::UnexpectedNodeTypeError) do
            visitor.walk([ApiQueryLanguage::Filtering::Nodes::Value.new(value: "x")])
          end
          assert_match(/ApiQueryLanguage::ActiveRecord::Sorting::Visitors::FieldSortVisitor/, err.message)
        end
      end
    end
  end
end
