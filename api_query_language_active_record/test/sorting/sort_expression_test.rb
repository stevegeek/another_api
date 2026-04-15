require "test_helper"

module ApiQueryLanguage
  module Sorting
    class SortExpressionTest < ::ApiQueryLanguageTestCase
      include TestInTempDatabase

      setup do
        @user1 = TestUserModel.create!(email: "foo@example.com", name: "Alice", failed_attempts: 5, deleted: false, tags: ["foo", "bar", "t1"])
        @user2 = TestUserModel.create!(email: "testy@example.com", name: "Bob", failed_attempts: 0, deleted: false, tags: ["t2", "bar"])
        @user3 = TestUserModel.create!(email: "another@example.com", name: "Sam", failed_attempts: -1, deleted: false, favorite_number: 7)
        @post1 = TestPostModel.create!(title: "Wow", test_user_model: @user1)
        @post2 = TestPostModel.create!(title: "Wow", test_user_model: @user2)
        @post3 = TestPostModel.create!(title: "Abc", test_user_model: @user3)
        @users = TestUserModel.all
        @posts = TestPostModel.all
      end

      def create_expression(query, attribute_mappings = @user1.attribute_names.map { |name| [name.to_sym, name] }.to_h)
        ::ApiQueryLanguage::ActiveRecord::Sorting::SortExpression.new(query, attribute_mappings)
      end

      def test_to_s
        query = create_expression("email:asc")
        assert_equal "ApiQueryLanguage::ActiveRecord::Sorting::SortExpression(sort_expression: 'email:asc')", query.to_s
      end

      def test_apply_to_desc
        query = create_expression("failed_attempts:desc")
        rel = query.apply_to(@users)
        assert_equal [@user1, @user2], rel.to_a[0..1]
      end

      def test_apply_to_asc
        query = create_expression("failed_attempts:asc")
        rel = query.apply_to(@users)
        assert_equal [@user3, @user2], rel.to_a[0..1]
      end

      def test_apply_to_multiple_fields
        query = create_expression("failed_attempts:desc;favorite_number:asc")
        rel = query.apply_to(@users)
        assert_equal [@user1, @user2, @user3], rel.to_a
      end

      def test_apply_to_datetime_field
        @user1.update!(locked_at: 1.day.ago)
        @user2.update!(locked_at: 2.days.ago)
        @user3.update!(locked_at: 3.days.ago)
        query = create_expression("locked_at:asc")
        rel = query.apply_to(@users)
        assert_equal [@user3, @user2, @user1], rel.to_a
      end

      def test_wont_apply_to_array_field
        omit_when_no_pg!
        query = create_expression("tags:asc")
        assert_raises(Errors::UnsupportedFieldTypeError) { query.apply_to(@users) }
      end

      def test_raises_when_invalid_query_expression
        assert_raises(Errors::InvalidExpressionError) { create_expression(nil) }
        assert_raises(Errors::InvalidExpressionError) { create_expression("") }
        assert_raises(Errors::InvalidExpressionError) { create_expression("a" * 1001) }
        assert_raises(Errors::InvalidExpressionError) { create_expression("foo") }
        assert_raises(Errors::InvalidExpressionError) { create_expression("foo:") }
        assert_raises(Errors::InvalidExpressionError) { create_expression("foo::test") }
      end

      # Testing mapping fields
      def test_mapping_a_field_to_another_attribute
        attribute_mappings = {e_mail: "email", full_name: "name", fails: "failed_attempts", deleted: nil, tags: nil}
        query = create_expression("fails:desc;full_name:asc", attribute_mappings)
        relation = query.apply_to(@users)
        assert_equal @user1, relation.first
        assert_equal "Alice", relation.first.name
      end

      def test_mapping_raises_when_mapping_not_found
        attribute_mappings = {e_mail: "email", full_name: "name", fails: "failed_attempts", deleted: nil, tags: nil}
        query = create_expression("my_name:asc", attribute_mappings)
        assert_raises(Errors::InvalidFieldError) { query.apply_to(@users) }
      end

      def test_mapping_a_field_to_another_attribute_with_join
        attribute_mappings = {title: nil, author_name: "test_user_model.name"}
        query = create_expression("title:desc;author_name:desc", attribute_mappings)
        relation = query.apply_to(@posts)
        assert_equal @post2, relation.first
        assert_equal "Wow", relation.first.title
        assert_equal "Bob", relation.first.author_name
      end

      def test_mapping_raises_when_joined_record_is_invalid
        attribute_mappings = {title: nil, author_name: "invalid_model.name"}
        query = create_expression("title:desc;author_name:desc", attribute_mappings)
        assert_raises(Errors::InvalidFieldValueError) { query.apply_to(@posts) }
      end

      # Testing nested fields

      def test_nested_field_filter
        attribute_mappings = {title: nil, "test_user_model.name": nil}
        query = create_expression("test_user_model.name:desc", attribute_mappings)
        relation = query.apply_to(@posts)
        assert_equal @post3, relation.first
      end

      def test_mapping_a_field_to_another_attribute_with_join_on_mapped_nested_field
        attribute_mappings = {title: nil, "author.name": "test_user_model.name"}
        query = create_expression("author.name:desc", attribute_mappings)
        relation = query.apply_to(@posts)
        assert_equal @post3, relation.first
      end

      def test_nested_field_via_has_many
        attribute_mappings = {"test_post_models.title": nil}
        query = create_expression("test_post_models.title:desc", attribute_mappings)
        relation = query.apply_to(@users)
        assert_equal @user1, relation.first
        assert_equal "Wow", relation.first.test_post_models.first.title
      end

      # Regression: apply_order_criteria must quote table/column identifiers
      # so that a reserved word or a name with a quote character does not
      # produce a SQL syntax error or injection. We verify by inspecting the
      # generated SQL rather than by actually malicious mappings, since the
      # parser would reject those at the AST layer.
      def test_apply_to_quotes_identifiers_in_the_generated_sql
        query = create_expression("name:asc")
        sql = query.apply_to(@users).to_sql
        # Sanity: the generated SQL must include quoted identifiers (driver-
        # specific: SQLite and PG both double-quote table/column names).
        assert_match(/"aql_test_users"|`aql_test_users`/, sql,
          "expected table name to be quoted in SELECT, got: #{sql}")
        assert_match(/"name"|`name`/, sql,
          "expected column name to be quoted in ORDER BY, got: #{sql}")
      end
    end
  end
end
