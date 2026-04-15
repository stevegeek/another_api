require "test_helper"
require "uri"

# Integration tests — exercise FilterExpression's SQL generation against a real
# ActiveRecord-backed SQLite database. Tests that depend on PG-only column
# types (array, jsonb) call `omit_when_no_pg!` and skip under SQLite.

module ApiQueryLanguage
  module Filtering
    class FilterExpressionTest < ::ApiQueryLanguageTestCase
      include TestInTempDatabase

      setup do
        @user1 = TestUserModel.create!(email: "foo@example.com", name: "Foo", failed_attempts: 5, deleted: false, tags: ["foo", "bar", "t1"])
        @user2 = TestUserModel.create!(email: "testy@example.com", name: "Testy", failed_attempts: 0, deleted: false, tags: ["t2", "bar"])
        @post1 = TestPostModel.create!(title: "Test", test_user_model: @user1)
        @post2 = TestPostModel.create!(title: "Another post 2", test_user_model: @user1)
        @post3 = TestPostModel.create!(title: "Test 3", test_user_model: @user2)
        @users = TestUserModel.all
        @posts = TestPostModel.all
      end

      def apply_query_to(query, expected_count:, relation: @users)
        filtered_relation = query.apply_to(relation)
        assert_equal expected_count, filtered_relation.count
        yield(filtered_relation) if block_given?
      end

      def create_expression(query, attribute_mappings = @user1.attribute_names.map { |name| [name.to_sym, name] }.to_h)
        ::ApiQueryLanguage::ActiveRecord::Filtering::FilterExpression.new(query, attribute_mappings)
      end

      def test_to_s
        query = create_expression("email:testy%40example.com")
        assert_equal "ApiQueryLanguage::ActiveRecord::Filtering::FilterExpression(filter_expression: 'email:testy%40example.com')", query.to_s
      end

      def test_apply_to
        query = create_expression("email:testy%40example.com")
        apply_query_to(query, expected_count: 1)
      end

      def test_apply_to_raises_when_column_not_found
        query = create_expression("my_email:testy%40example.com")
        assert_raises(Errors::InvalidFieldError) { apply_query_to(query, expected_count: 1) }
      end

      def test_apply_to_raises_when_column_with_comparison_not_found
        query = create_expression("my_email{eq}:testy%40example.com")
        assert_raises(Errors::InvalidFieldError) { apply_query_to(query, expected_count: 1) }
      end

      def test_raises_when_invalid_query_expression
        assert_raises(Errors::InvalidExpressionError) { create_expression(nil) }
        assert_raises(Errors::InvalidExpressionError) { create_expression("") }
        assert_raises(Errors::InvalidExpressionError) { create_expression("a" * 1001) }
        assert_raises(Errors::InvalidExpressionError) { create_expression("foo") }
        assert_raises(Errors::InvalidExpressionError) { create_expression("foo:") }
        assert_raises(Errors::InvalidExpressionError) { create_expression("foo::test") }
      end

      # Column types and casting tests

      def test_apply_to_with_string
        @user1.update!(unlock_token: "123")
        query = create_expression("unlock_token:123")
        apply_query_to(query, expected_count: 1)
      end

      def test_apply_to_with_integer
        query = create_expression("failed_attempts:5")
        apply_query_to(query, expected_count: 1)
      end

      def test_apply_to_with_integer_with_non_integer_value_with_cast
        query = create_expression("failed_attempts:5.5")
        apply_query_to(query, expected_count: 1)
      end

      def test_raises_when_apply_to_with_integer_with_non_numeric_value
        query = create_expression("failed_attempts:foo")
        assert_raises { query.apply_to(@users) }
      end

      def test_apply_to_with_decimal
        query = create_expression("favorite_number:0.0")
        apply_query_to(query, expected_count: 2)
        @user1.update!(favorite_number: 0.1)
        apply_query_to(query, expected_count: 1)
      end

      def test_apply_to_with_decimal_with_value_to_cast
        query = create_expression("favorite_number:10")
        apply_query_to(query, expected_count: 0)
        @user1.update!(favorite_number: 10.0)
        apply_query_to(query, expected_count: 1)
      end

      def test_raises_when_unsupported_field_type
        omit_when_no_pg!
        query = create_expression("metadata:test")
        assert_raises(Errors::UnsupportedFieldTypeError) { query.apply_to(@users) }
      end

      def test_apply_to_with_boolean
        query = create_expression("deleted:false")
        apply_query_to(query, expected_count: 2)
        @user1.update!(deleted: true)
        apply_query_to(query, expected_count: 1)
        query = create_expression("deleted:true")
        apply_query_to(query, expected_count: 1)
        query = create_expression("deleted:1")
        apply_query_to(query, expected_count: 1)
        query = create_expression("deleted:0")
        apply_query_to(query, expected_count: 1)
        query = create_expression("deleted:True [or] deleted:False")
        apply_query_to(query, expected_count: 2)
      end

      def test_apply_to_with_boolean_with_non_boolean_value
        query = create_expression("deleted:foo")
        assert_raises(Errors::InvalidFieldValueError) { query.apply_to(@users) }
      end

      def test_apply_to_with_date
        @user1.update!(birthday: Date.parse("2020-01-01"))
        query = create_expression("birthday:#{URI.encode_uri_component("2020-01-01")}")
        apply_query_to(query, expected_count: 1)
      end

      def test_apply_to_with_date_with_invalid_value
        query = create_expression("birthday:foo")
        assert_raises(Errors::InvalidFieldValueError) { query.apply_to(@users) }
      end

      # Also tests time zone conversion
      def test_apply_to_with_datetime
        @user1.update!(created_at: DateTime.parse("2020-01-01T00:00:00Z"))
        query = create_expression("created_at:#{URI.encode_uri_component("2020-01-01T00:00:00Z")}")
        apply_query_to(query, expected_count: 1)
        # in different timezone, but same time
        @user2.update!(created_at: "2020-01-01T01:00:00+01:00")
        apply_query_to(query, expected_count: 2)
        query = create_expression("created_at:#{URI.encode_uri_component("2020-01-01T01:00:00+01:00")}")
        apply_query_to(query, expected_count: 2)
      end

      def test_datetime_with_condition
        @user1.update!(created_at: DateTime.parse("2020-01-01T00:00:00Z"))
        query = create_expression("created_at{gt}:#{URI.encode_uri_component("2019-01-01T00:00:00Z")}")
        apply_query_to(query, expected_count: 2)
        query = create_expression("created_at{lt}:#{URI.encode_uri_component("2022-01-01T00:00:00Z")}")
        apply_query_to(query, expected_count: 1)
        query = create_expression("created_at{lt}:#{URI.encode_uri_component("2050-01-01T00:00:00Z")}")
        apply_query_to(query, expected_count: 2)
      end

      def test_apply_to_with_datetime_with_invalid_value
        query = create_expression("created_at:foo")
        assert_raises(Errors::InvalidFieldValueError) { query.apply_to(@users) }
      end

      def test_apply_to_with_time
        @user1.update!(alarm: Time.zone.parse("00:00:00"))
        query = create_expression("alarm:#{URI.encode_uri_component("00:00:00")}")
        apply_query_to(query, expected_count: 1)
      end

      def test_apply_to_with_time_with_invalid_value
        query = create_expression("alarm:foo")
        assert_raises(Errors::InvalidFieldValueError) { query.apply_to(@users) }
      end

      def test_apply_to_with_float
        query = create_expression("temperature:0.0")
        apply_query_to(query, expected_count: 2)
        @user1.update!(temperature: 0.1)
        apply_query_to(query, expected_count: 1)
      end

      def test_apply_to_with_float_not_a_valid_number
        query = create_expression("temperature:foo")
        assert_raises(Errors::InvalidFieldValueError) { query.apply_to(@users) }
      end

      # Below are #apply_to tests, these efficiently test the query parser and the visitors

      def test_simple_query_or_value
        query = create_expression("email:testy%40example.com|foobar%40example.com")
        apply_query_to(query, expected_count: 1)
      end

      def test_simple_query_and_value
        omit_when_no_pg!
        query = create_expression("tags:t2&bar")
        apply_query_to(query, expected_count: 1) do |relation|
          assert_includes relation.first.tags, "t2"
        end
      end

      def test_multiple_conditions_on_same_field_and
        omit_when_no_pg!
        query = create_expression("tags:bar [and] tags:foo|t2")
        apply_query_to(query, expected_count: 2)
      end

      def test_multiple_conditions_on_same_field_and_type_integer
        omit_when_no_pg!
        @user1.update!(lottery_numbers: [1, 2])
        query = create_expression("lottery_numbers:1 [and] lottery_numbers:2")
        apply_query_to(query, expected_count: 1)
      end

      def test_multiple_value_conditions_with_type_integer
        omit_when_no_pg!
        @user1.update!(lottery_numbers: [1, 2])
        query = create_expression("lottery_numbers:1 & 2")
        apply_query_to(query, expected_count: 1)
      end

      def test_raises_when_multiple_value_conditions_with_type_integer_invalid_value
        omit_when_no_pg!
        query = create_expression("lottery_numbers:1 & foo")
        assert_raises(Errors::InvalidFieldValueError) { query.apply_to(@users) }
      end

      def test_multiple_conditions_on_same_field_or
        omit_when_no_pg!
        query = create_expression("tags: t1 [or] tags: foo & t2")
        apply_query_to(query, expected_count: 1) do |relation|
          refute_includes relation.first.tags, "t2"
        end
      end

      def test_multiple_conditions_and
        query = create_expression("failed_attempts:0[and]email:testy%40example.com")
        apply_query_to(query, expected_count: 1) do |relation|
          assert_equal "testy@example.com", relation.first.email
        end
        query = create_expression("failed_attempts:1[and]email:testy%40example.com")
        apply_query_to(query, expected_count: 0)
      end

      def test_multiple_conditions_or
        query = create_expression("failed_attempts:2[or]email:testy%40example.com")
        apply_query_to(query, expected_count: 1) do |relation|
          result = relation.first
          assert_equal "testy@example.com", result.email
          assert result.failed_attempts.zero?
        end
      end

      def test_condition_with_gte_comparison
        query = create_expression("failed_attempts{gte}:3")
        apply_query_to(query, expected_count: 1) do |relation|
          result = relation.first
          assert result.failed_attempts >= 3
        end
      end

      def test_condition_with_gt_comparison
        query = create_expression("failed_attempts{gt}:3")
        apply_query_to(query, expected_count: 1)
        query = create_expression("failed_attempts{gt}:100")
        apply_query_to(query, expected_count: 0)
      end

      def test_condition_with_lte_comparison
        query = create_expression("failed_attempts{lte}:3")
        apply_query_to(query, expected_count: 1) do |relation|
          result = relation.first
          assert result.failed_attempts <= 3
        end
      end

      def test_condition_with_lt_comparison
        query = create_expression("failed_attempts{lt}:3")
        apply_query_to(query, expected_count: 1) do |relation|
          result = relation.first
          assert result.failed_attempts < 3
        end
      end

      def test_condition_with_neq_comparison
        query = create_expression("failed_attempts{neq}:3")
        apply_query_to(query, expected_count: 2)
      end

      def test_condition_with_eq_comparison
        query = create_expression("failed_attempts{eq}:3")
        apply_query_to(query, expected_count: 0)
        query = create_expression("failed_attempts{eq}:5")
        apply_query_to(query, expected_count: 1)
      end

      def test_condition_with_case_insensitive
        query = create_expression("email{ieq}:TESTy%40example.com")
        apply_query_to(query, expected_count: 1)
      end

      def test_condition_with_case_insensitive_is_sanitized
        query = create_expression("email{ieq}:%25Ty%40example.com")
        apply_query_to(query, expected_count: 0)
      end

      def test_condition_with_null
        query = create_expression("null(locked_at)")
        apply_query_to(query, expected_count: 2) do |relation|
          result = relation.first
          assert result.locked_at.nil?

          result.update!(locked_at: Time.zone.now)
        end
        apply_query_to(query, expected_count: 1)
      end

      def test_condition_with_not_null
        query = create_expression("[not] null(locked_at)")
        apply_query_to(query, expected_count: 0)
        @user1.update!(locked_at: Time.zone.now)
        apply_query_to(query, expected_count: 1)
      end

      def test_condition_with_not_null_and_grouping
        query = create_expression("[not] (email: testy%40example.com [and] null(locked_at))")
        apply_query_to(query, expected_count: 1)
        @user2.update!(locked_at: Time.zone.now)
        apply_query_to(query, expected_count: 2)
      end

      # Value expressions on array columns — tests the AND (&) and OR (|) operators
      # when the field is a PostgreSQL array column (e.g. tags string[]).

      def test_value_expression_or_on_array_field
        omit_when_no_pg!
        # tags:foo|bar matches rows that have either "foo" OR "bar" in the array
        query = create_expression("tags:foo|bar")
        apply_query_to(query, expected_count: 2) # both @user1 (has foo) and @user2 (has bar) match
      end

      def test_value_expression_and_on_array_field
        omit_when_no_pg!
        # tags:foo&bar matches rows that have both "foo" AND "bar" in the array
        query = create_expression("tags:foo&bar")
        apply_query_to(query, expected_count: 1) do |relation|
          # Only @user1 has both foo and bar
          assert_includes relation.first.tags, "foo"
          assert_includes relation.first.tags, "bar"
        end
      end

      def test_value_expression_and_on_array_field_no_match
        omit_when_no_pg!
        # tags:foo&t2 — @user1 has foo but not t2, @user2 has t2 but not foo
        query = create_expression("tags:foo&t2")
        apply_query_to(query, expected_count: 0)
      end

      def test_value_expression_or_on_array_field_combined_with_condition
        omit_when_no_pg!
        # tags:t1|t2 [and] deleted:false
        query = create_expression("tags:t1|t2 [and] deleted:false")
        apply_query_to(query, expected_count: 2)
      end

      def test_grouping
        query = create_expression("deleted:false [and] (failed_attempts: 2 [or] email: testy%40example.com)")
        apply_query_to(query, expected_count: 1)
      end

      def test_grouping_2
        query = create_expression("(deleted:false [and] failed_attempts: 2) [or] email: testy%40example.com")
        apply_query_to(query, expected_count: 1)
      end

      def test_grouping_3
        query = create_expression("(deleted:false) [and] (failed_attempts: 2) [or] (email: testy%40example.com)")
        apply_query_to(query, expected_count: 1)
      end

      def test_grouping_4
        query = create_expression("deleted:false [or] (failed_attempts: 2 [and] (null(deleted_at) [or] (null(locked_at) [and] null(unlock_token)))) [or] (email: testy%40example.com [or] null(locked_at))")
        apply_query_to(query, expected_count: 2)
      end

      # Testing wildcard

      def test_using_wildcard
        query = create_expression("email:*example.com")
        apply_query_to(query, expected_count: 2)
      end

      def test_that_wildcard_is_case_insensitive
        query = create_expression("email:*EXAMPLE.COM")
        apply_query_to(query, expected_count: 2)
      end

      def test_that_wildcard_expression_is_sanitized
        query = create_expression("email:%25example.*")
        apply_query_to(query, expected_count: 0)
      end

      def test_raises_when_using_wildcard_on_invalid_field_type
        query = create_expression("failed_attempts:*1")
        assert_raises(Errors::UnsupportedFieldTypeError) { query.apply_to(@users) }
      end

      # Testing mapping fields
      def test_mapping_a_field_to_another_attribute
        attribute_mappings = {e_mail: "email", full_name: "name", fails: "failed_attempts", deleted: nil, tags: nil}
        query = create_expression("full_name:Foo [and] fails{gt}:3", attribute_mappings)
        apply_query_to(query, expected_count: 1) do |relation|
          assert_equal "Foo", relation.first.name
        end
      end

      def test_mapping_raises_when_mapping_not_found
        attribute_mappings = {e_mail: "email", full_name: "name", fails: "failed_attempts", deleted: nil, tags: nil}
        query = create_expression("my_name:Foo", attribute_mappings)
        assert_raises(Errors::InvalidFieldError) { query.apply_to(@users) }
      end

      def test_mapping_a_field_to_another_attribute_with_join
        attribute_mappings = {title: nil, author_name: "test_user_model.name"}
        query = create_expression("title:Test [and] author_name:Foo", attribute_mappings)
        apply_query_to(query, relation: @posts, expected_count: 1) do |relation|
          assert_equal "Foo", relation.first.author_name
        end
      end

      def test_mapping_raises_when_joined_record_is_invalid
        attribute_mappings = {title: nil, author_name: "invalid_model.name"}
        query = create_expression("title:Test [and] author_name:Bar", attribute_mappings)
        assert_raises(Errors::InvalidFieldValueError) { query.apply_to(@posts) }
      end

      # Testing nested fields

      def test_nested_field_filter
        attribute_mappings = {title: nil, "test_user_model.name": nil}
        query = create_expression("test_user_model.name:Foo", attribute_mappings)
        apply_query_to(query, relation: @posts, expected_count: 2) do |relation|
          assert_equal "Foo", relation.first.author_name
        end
      end

      def test_nested_filter_with_comparison
        attribute_mappings = {title: nil, "test_user_model.failed_attempts": nil}
        query = create_expression("test_user_model.failed_attempts{lt}:4", attribute_mappings)
        apply_query_to(query, relation: @posts, expected_count: 1) do |relation|
          assert_equal 0, relation.first.test_user_model.failed_attempts
        end
      end

      def test_nested_filter_with_negation
        attribute_mappings = {title: nil, "test_user_model.name": nil}
        query = create_expression("[not] test_user_model.name:Foo", attribute_mappings)
        apply_query_to(query, relation: @posts, expected_count: 1) do |relation|
          assert_equal "Testy", relation.first.test_user_model.name
        end
      end

      def test_mapping_a_field_to_another_attribute_with_join_on_mapped_nested_field
        attribute_mappings = {title: nil, "author.name": "test_user_model.name"}
        query = create_expression("title:Test [and] author.name:Foo", attribute_mappings)
        apply_query_to(query, relation: @posts, expected_count: 1) do |relation|
          assert_equal "Foo", relation.first.author_name
        end
      end

      def test_mapping_a_field_to_another_attribute_with_join_on_mapped_nested_field_with_comparison
        attribute_mappings = {title: nil, "author.failed_attempts": "test_user_model.failed_attempts"}
        query = create_expression("title:Test%203 [and] author.failed_attempts{lt}:4", attribute_mappings)
        apply_query_to(query, relation: @posts, expected_count: 1) do |relation|
          assert_equal 0, relation.first.test_user_model.failed_attempts
        end
      end

      def test_mapping_a_field_to_another_attribute_with_join_on_mapped_nested_field_with_negation
        attribute_mappings = {title: nil, "author.name": "test_user_model.name"}
        query = create_expression("title:Test%203 [and] [not] author.name:Foo", attribute_mappings)
        apply_query_to(query, relation: @posts, expected_count: 1) do |relation|
          assert_equal "Testy", relation.first.test_user_model.name
        end
      end

      # Testing matching on nested in array fields
      def test_matching_one_or_more_on_nested_in_array_field
        attribute_mappings = {"posts.title": "test_post_models.title"}
        query = create_expression("posts.title:Test*", attribute_mappings)
        apply_query_to(query, relation: @users, expected_count: 2) do |relation|
          assert_equal "Foo", relation.first.name
        end
      end

      def test_matching_zero_or_more_on_nested_in_array_field
        attribute_mappings = {"posts.title": "test_post_models.title"}
        query = create_expression("posts.title:Test+", attribute_mappings)
        apply_query_to(query, relation: @users, expected_count: 1) do |relation|
          assert_equal "Testy", relation.first.name
        end
      end

      # Testing value transforms (queryable: {transform: ...})
      # Uses a Data object that responds to :column and :transform, mimicking QueryableConfig

      QueryableMapping = Data.define(:column, :transform, :filter, :sort, :allowed_values) do
        def initialize(column: nil, transform: nil, filter: true, sort: true, allowed_values: nil)
          super
        end
      end

      def test_value_transform_applied_before_filtering
        # Transform converts lowercase input to uppercase to match DB convention
        upcase_transform = ->(value) { value.upcase }
        attribute_mappings = {
          name: QueryableMapping.new(column: "name", transform: upcase_transform)
        }
        # DB has "Foo" but we search with "foo" — transform upcases to "FOO", no match
        query = ::ApiQueryLanguage::ActiveRecord::Filtering::FilterExpression.new("name:foo", attribute_mappings)
        apply_query_to(query, expected_count: 0)

        # Transform "Foo" → "FOO", still no match because DB has "Foo" not "FOO"
        query = ::ApiQueryLanguage::ActiveRecord::Filtering::FilterExpression.new("name:Foo", attribute_mappings)
        apply_query_to(query, expected_count: 0)
      end

      def test_value_transform_with_lookup
        # Transform simulates a UoM lookup: maps a human symbol to an internal code
        symbol_to_email = ->(value) { {"admin" => "foo@example.com", "tester" => "testy@example.com"}[value] || value }
        attribute_mappings = {
          user_type: QueryableMapping.new(column: "email", transform: symbol_to_email)
        }
        # API consumer sends "admin" which maps to "foo@example.com" in the DB
        query = ::ApiQueryLanguage::ActiveRecord::Filtering::FilterExpression.new("user_type:admin", attribute_mappings)
        apply_query_to(query, expected_count: 1) do |relation|
          assert_equal "foo@example.com", relation.first.email
        end
      end

      def test_value_transform_with_comparison_operator
        # Transform that maps string labels to numeric values
        severity_map = ->(value) { {"low" => "0", "medium" => "3", "high" => "5"}[value] || value }
        attribute_mappings = {
          severity: QueryableMapping.new(column: "failed_attempts", transform: severity_map)
        }
        query = ::ApiQueryLanguage::ActiveRecord::Filtering::FilterExpression.new("severity{gte}:medium", attribute_mappings)
        apply_query_to(query, expected_count: 1) do |relation|
          assert relation.first.failed_attempts >= 3
        end
      end

      def test_no_transform_when_mapping_has_none
        # Plain QueryableMapping without a transform — should work like a normal column mapping
        attribute_mappings = {
          full_name: QueryableMapping.new(column: "name")
        }
        query = ::ApiQueryLanguage::ActiveRecord::Filtering::FilterExpression.new("full_name:Foo", attribute_mappings)
        apply_query_to(query, expected_count: 1) do |relation|
          assert_equal "Foo", relation.first.name
        end
      end

      # Testing allowed_values enforcement (queryable: {allowed_values: [...]})

      def test_allowed_values_permits_valid_value
        attribute_mappings = {
          name: QueryableMapping.new(column: "name", allowed_values: %w[Foo Testy])
        }
        query = ::ApiQueryLanguage::ActiveRecord::Filtering::FilterExpression.new("name:Foo", attribute_mappings)
        apply_query_to(query, expected_count: 1) do |relation|
          assert_equal "Foo", relation.first.name
        end
      end

      def test_allowed_values_rejects_disallowed_value
        attribute_mappings = {
          name: QueryableMapping.new(column: "name", allowed_values: %w[Foo Testy])
        }
        query = ::ApiQueryLanguage::ActiveRecord::Filtering::FilterExpression.new("name:NotAllowed", attribute_mappings)
        assert_raises(Errors::DisallowedValueError) { query.apply_to(@users) }
      end

      def test_allowed_values_nil_does_not_restrict
        attribute_mappings = {
          name: QueryableMapping.new(column: "name", allowed_values: nil)
        }
        query = ::ApiQueryLanguage::ActiveRecord::Filtering::FilterExpression.new("name:Foo", attribute_mappings)
        apply_query_to(query, expected_count: 1)
      end

      def test_allowed_values_with_transform
        # allowed_values check runs BEFORE the transform
        upcase_transform = ->(value) { value.upcase }
        attribute_mappings = {
          name: QueryableMapping.new(column: "name", transform: upcase_transform, allowed_values: %w[foo bar])
        }
        # "foo" is in allowed_values, so passes validation, then gets transformed to "FOO"
        query = ::ApiQueryLanguage::ActiveRecord::Filtering::FilterExpression.new("name:foo", attribute_mappings)
        apply_query_to(query, expected_count: 0) # "FOO" won't match "Foo" in DB

        # "baz" is NOT in allowed_values — raises before transform runs
        query = ::ApiQueryLanguage::ActiveRecord::Filtering::FilterExpression.new("name:baz", attribute_mappings)
        assert_raises(Errors::DisallowedValueError) { query.apply_to(@users) }
      end
    end
  end
end
