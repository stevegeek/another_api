# frozen_string_literal: true

require "test_helper"

# Exercises the FilteredAndSorted, ParamDeserializer, Paginated and Serializes
# concerns end-to-end, plus the ApiTokenOwnershipPolicy variant.
class PostsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    Post.delete_all
    ApiToken.delete_all
    Bearer.delete_all
    @bearer = Bearer.create!(name: "owner")
    @other_bearer = Bearer.create!(name: "stranger")
    @token = "dt_owner_token_aaa_bbb"
    ApiToken.create_with_raw!(@token,
      bearer: @bearer,
      scopes: %w[
        api.test.posts.list api.test.posts.show api.test.posts.create
        api.test.posts.update api.test.posts.delete
      ])
    @other_token = "dt_other_token_aaa_bbb"
    ApiToken.create_with_raw!(@other_token,
      bearer: @other_bearer,
      scopes: %w[api.test.posts.show])
  end

  def auth_headers(token = @token, extra = {})
    {"Authorization" => "Bearer #{token}", "Accept" => "application/json"}.merge(extra)
  end

  test "GET /posts paginates" do
    10.times { |i| Post.create!(title: "t#{i}", bearer: @bearer) }
    get "/api/test/posts", headers: auth_headers, params: {page_size: 3, page: 2}
    assert_response :ok
    body = JSON.parse(response.body, symbolize_names: true)
    assert_equal 3, body[:data].length
    assert_equal 2, body[:page]
    assert_equal 3, body[:page_size]
  end

  test "GET /posts honours sort param" do
    Post.create!(title: "Bravo", bearer: @bearer)
    Post.create!(title: "Alpha", bearer: @bearer)
    get "/api/test/posts", headers: auth_headers, params: {sort: "title:asc"}
    titles = JSON.parse(response.body, symbolize_names: true)[:data].map { |p| p[:title] }
    assert_equal %w[Alpha Bravo], titles
  end

  test "GET /posts honours filter param" do
    Post.create!(title: "Alpha", bearer: @bearer)
    Post.create!(title: "Bravo", bearer: @bearer)
    get "/api/test/posts", headers: auth_headers, params: {filter: "title:Alpha"}
    titles = JSON.parse(response.body, symbolize_names: true)[:data].map { |p| p[:title] }
    assert_equal ["Alpha"], titles
  end

  test "GET /posts returns 400 on malformed filter expression" do
    get "/api/test/posts", headers: auth_headers, params: {filter: "this-is-not-a-filter"}
    assert_response :bad_request
  end

  test "POST /posts deserializes JSON body via the schema" do
    post "/api/test/posts",
      headers: auth_headers.merge("Content-Type" => "application/json"),
      params: {title: "New Post", body: "Body text"}.to_json
    assert_response :created
    body = JSON.parse(response.body, symbolize_names: true)
    assert_equal "New Post", body[:data][:title]
    assert_equal "Body text", body[:data][:body]
  end

  test "POST /posts returns validation error when title is missing" do
    post "/api/test/posts",
      headers: auth_headers.merge("Content-Type" => "application/json"),
      params: {body: "no title"}.to_json
    assert_response :bad_request
    body = JSON.parse(response.body, symbolize_names: true)
    refute body[:success]
  end

  test "GET /posts/:id returns the post when bearer owns it (ownership policy passes)" do
    p = Post.create!(title: "Mine", bearer: @bearer)
    get "/api/test/posts/#{p.id}", headers: auth_headers
    assert_response :ok
    body = JSON.parse(response.body, symbolize_names: true)
    assert_equal "Mine", body[:data][:title]
  end

  test "GET /posts/:id returns 403 when bearer does not own the post" do
    p = Post.create!(title: "Theirs", bearer: @bearer)
    get "/api/test/posts/#{p.id}", headers: auth_headers(@other_token)
    assert_response :forbidden
  end

  # ------------------------------------------------------------------
  # FilteredAndSorted apply-time error rescues — these only fire when
  # an ApiQueryLanguage error escapes the parser and bubbles out of
  # `apply_to`. Schemas that map onto missing columns or that constrain
  # values via allowed_values are how we trigger them naturally.
  # ------------------------------------------------------------------

  test "filter on a field whose allowed_values reject the value → 400" do
    Post.create!(title: "Hi", bearer: @bearer)
    get "/api/test/posts", headers: auth_headers, params: {filter: "status:archived"}
    assert_response :bad_request
    body = JSON.parse(response.body, symbolize_names: true)
    assert_equal "bad_request", body[:error_type]
  end

  test "filter on a field whose mapped column does not exist → 400" do
    Post.create!(title: "Hi", bearer: @bearer)
    get "/api/test/posts", headers: auth_headers, params: {filter: "missing_column:foo"}
    assert_response :bad_request
  end

  # Note: a sort on a missing column would only blow up at SQL execution
  # time (SQLite raises StatementInvalid), not in the FilteredAndSorted
  # rescue chain — so there's no test for that here. The filter-side
  # missing_column test above covers the equivalent visitor path.

  # ------------------------------------------------------------------
  # default_filter / default_sort callables (no filter/sort params).
  # ------------------------------------------------------------------

  test "GET /posts/defaults_index with no filter param applies default_filter" do
    Post.create!(title: "Default", bearer: @bearer)
    Post.create!(title: "Other", bearer: @bearer)
    get "/api/test/posts/defaults_index", headers: auth_headers
    body = JSON.parse(response.body, symbolize_names: true)
    titles = body[:data].map { |p| p[:title] }
    assert_equal ["Default"], titles
  end

  test "GET /posts/defaults_index with no sort param applies default_sort (desc by id)" do
    Post.create!(title: "Default", bearer: @bearer) # id=1
    Post.create!(title: "Default", bearer: @bearer) # id=2
    Post.create!(title: "Default", bearer: @bearer) # id=3
    get "/api/test/posts/defaults_index", headers: auth_headers
    body = JSON.parse(response.body, symbolize_names: true)
    ids = body[:data].map { |p| p[:id] }
    assert_equal ids, ids.sort.reverse
  end

  test "malformed sort expression → 400" do
    Post.create!(title: "Hi", bearer: @bearer)
    get "/api/test/posts", headers: auth_headers, params: {sort: "this-isnt-a-sort"}
    assert_response :bad_request
  end
end
