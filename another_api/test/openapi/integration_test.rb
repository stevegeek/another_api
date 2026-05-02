# frozen_string_literal: true

require "test_helper"
require "another_api/openapi"

# Real-world end-to-end test: generates an OpenAPI 3.1 spec for the dummy
# Rails app's Test::PostsController and Test::WidgetsController, both of
# which `include AnotherApi::OpenAPI::EndpointMetadata` and use the
# `api_resource` / `api_action` DSL.
#
# This proves the entire chain works:
#   controller class load
#     -> api_action declaration
#       -> EndpointRegistry registration
#         -> Generator route lookup via Rails.application.routes
#           -> SchemaBuilder walks ApiSerializer schemas
#             -> PathBuilder produces operations gated on concerns
#               -> resulting spec hash
class AnotherApi::OpenAPI::IntegrationTest < ActionDispatch::IntegrationTest
  CONTROLLER_FILES = [
    File.expand_path("../dummy/app/controllers/test/posts_controller.rb", __dir__),
    File.expand_path("../dummy/app/controllers/test/widgets_controller.rb", __dir__)
  ].freeze

  def setup
    @prev = AnotherApi::OpenAPI.instance_variable_get(:@configuration)
    AnotherApi::OpenAPI.reset_configuration!
    AnotherApi::OpenAPI::EndpointRegistry.clear!

    # Re-apply the configuration the dummy initializer originally set;
    # other tests may have called reset_configuration! between runs.
    AnotherApi::OpenAPI.configure do |c|
      c.title = "Dummy API"
      c.version = "0.1"
      c.description = "Reference dummy app demonstrating AnotherApi::OpenAPI."
      c.path_prefix = "/api/test"
      c.controllers_glob = "app/controllers/test/*_controller.rb"
      c.schema_namespace_prefix = "CoreSchemas::V2::"
      c.default_variant_name = :default
      c.additional_discovery_variants = [:default]
    end

    # Force the controller class bodies to re-evaluate so api_action calls
    # re-register their entries. Classes get redefined; suppress the
    # method-redefinition warnings that come with that.
    silence_warnings do
      CONTROLLER_FILES.each { |f| load f }
    end

    @spec = AnotherApi::OpenAPI::Generator.generate
  end

  def teardown
    AnotherApi::OpenAPI::EndpointRegistry.clear!
    AnotherApi::OpenAPI.instance_variable_set(:@configuration, @prev)
  end

  # ------------------------------------------------------------------
  # Top-level spec shape
  # ------------------------------------------------------------------

  test "spec uses OpenAPI 3.1.0 with configured info and servers" do
    assert_equal "3.1.0", @spec[:openapi]
    assert_equal "Dummy API", @spec[:info][:title]
    assert_equal "0.1", @spec[:info][:version]
    assert_equal "Reference dummy app demonstrating AnotherApi::OpenAPI.", @spec[:info][:description]
    assert_equal [{url: "/api/test"}], @spec[:servers]
  end

  test "spec includes bearer-auth security scheme and global security requirement" do
    assert_equal "http", @spec[:components][:securitySchemes][:bearerAuth][:type]
    assert_equal "bearer", @spec[:components][:securitySchemes][:bearerAuth][:scheme]
    assert_equal [{bearerAuth: []}], @spec[:security]
  end

  test "common parameters and PaginationMetadata are wired into components" do
    assert @spec[:components][:parameters].key?(:page)
    assert @spec[:components][:parameters].key?(:filter)
    assert @spec[:components][:schemas].key?("PaginationMetadata")
    assert @spec[:components][:schemas].key?("FilterExpression")
  end

  # ------------------------------------------------------------------
  # Posts: full CRUD-ish, with concerns
  # ------------------------------------------------------------------

  test "Posts paths resolve relative to the path_prefix" do
    assert @spec[:paths].key?("/posts"), "expected /posts; got #{@spec[:paths].keys.inspect}"
    assert @spec[:paths].key?("/posts/{id}")
    assert @spec[:paths].key?("/posts/defaults_index")
  end

  test "Posts index advertises page, page_size, filter, sort, variant" do
    # Posts inherits Paginated + SchemaConfigurable from BaseController and
    # explicitly includes FilteredAndSorted, so all of these should appear.
    refs = @spec[:paths]["/posts"]["get"][:parameters].map { |p| p["$ref"] }.compact

    %w[page page_size filter sort variant].each do |name|
      assert_includes refs, "#/components/parameters/#{name}"
    end
  end

  test "Posts index returns array of PostFull with PaginationMetadata" do
    body = @spec[:paths]["/posts"]["get"][:responses]["200"][:content]["application/json"][:schema]
    assert_equal "array", body[:properties][:data][:type]
    assert_equal "#/components/schemas/PostFull", body[:properties][:data][:items]["$ref"]
    assert_equal "#/components/schemas/PaginationMetadata", body[:properties][:metadata]["$ref"]
  end

  test "Posts show returns single PostFull and advertises 404" do
    op = @spec[:paths]["/posts/{id}"]["get"]
    body = op[:responses]["200"][:content]["application/json"][:schema]
    assert_equal "#/components/schemas/PostFull", body[:properties][:data]["$ref"]
    assert op[:responses]["404"], "show should advertise 404"
  end

  test "Posts create accepts PostCreateInput body and returns 201" do
    op = @spec[:paths]["/posts"]["post"]
    body_schema = op[:requestBody][:content]["application/json"][:schema]
    assert_equal "#/components/schemas/PostCreateInput", body_schema["$ref"]
    assert op[:responses]["201"]
    refute op[:responses]["200"]
  end

  test "Posts defaults_index custom collection action is documented with auto-detected verb" do
    op = @spec[:paths]["/posts/defaults_index"]["get"]
    assert_equal "List posts with default filter and sort applied", op[:summary]
  end

  test "PostFull schema reflects the api_serializer attributes" do
    post_full = @spec[:components][:schemas]["PostFull"]
    assert_equal "object", post_full[:type]
    %i[id title body status missing_column].each do |attr|
      assert post_full[:properties].key?(attr), "PostFull missing property #{attr}"
    end
    # status has allowed_values → enum
    assert_equal %w[draft published], post_full[:properties][:status][:enum]
    # body is _Nilable so should not be required
    assert post_full[:required].include?("title")
    refute post_full[:required].include?("body")
  end

  test "PostCreateInput deserializer schema is generated alongside" do
    input = @spec[:components][:schemas]["PostCreateInput"]
    assert input[:properties].key?(:title)
    assert input[:properties].key?(:body)
  end

  # ------------------------------------------------------------------
  # Widgets: same DSL, but no Paginated/FilteredAndSorted concerns
  # ------------------------------------------------------------------

  test "Widgets paths exist for declared actions only" do
    assert @spec[:paths].key?("/widgets")
    assert @spec[:paths].key?("/widgets/{id}")
    # update/destroy are declared in routes but the controller doesn't
    # implement them, so the DSL doesn't declare them either; we expect
    # only get/post on /widgets and get on /widgets/{id}.
    assert @spec[:paths]["/widgets"].key?("get")
    assert @spec[:paths]["/widgets"].key?("post")
    assert @spec[:paths]["/widgets/{id}"].key?("get")
    refute @spec[:paths]["/widgets/{id}"]&.key?("patch")
    refute @spec[:paths]["/widgets/{id}"]&.key?("delete")
  end

  test "Widgets index advertises page/page_size/variant (inherited from BaseController) but NOT filter/sort" do
    # WidgetsController doesn't include FilteredAndSorted, so filter/sort
    # should NOT be advertised — this is the real value of the gating: it
    # discriminates between controllers with vs without query-language concerns.
    refs = @spec[:paths]["/widgets"]["get"][:parameters].map { |p| p["$ref"] }.compact

    assert_includes refs, "#/components/parameters/page",
      "page is inherited from BaseController#include Paginated"
    assert_includes refs, "#/components/parameters/page_size"
    assert_includes refs, "#/components/parameters/variant",
      "variant is inherited from BaseController#include SchemaConfigurable"

    refute_includes refs, "#/components/parameters/filter",
      "Widgets does not include FilteredAndSorted"
    refute_includes refs, "#/components/parameters/sort"
  end

  test "Widgets responses use generic object body when no schema lambda is configured" do
    body = @spec[:paths]["/widgets"]["get"][:responses]["200"][:content]["application/json"][:schema]
    # data is array of generic objects (no schema_ref → falls back to {type: "object"})
    assert_equal "array", body[:properties][:data][:type]
    assert_equal "object", body[:properties][:data][:items][:type]
  end

  # ------------------------------------------------------------------
  # Operation IDs
  # ------------------------------------------------------------------

  test "operation IDs are deterministic and unique across paths" do
    op_ids = @spec[:paths].flat_map { |_path, verbs| verbs.values.map { |op| op[:operationId] } }
    assert_equal op_ids, op_ids.uniq, "duplicate operationIds: #{(op_ids - op_ids.uniq).inspect}"
    assert_includes op_ids, "index_posts"
    assert_includes op_ids, "create_posts"
    assert_includes op_ids, "show_posts"
    # The custom collection action has the action segment in the path too,
    # so the op-id format ends up doubled. Not pretty, but deterministic.
    assert_includes op_ids, "defaults_index_posts_defaults_index"
    assert_includes op_ids, "index_widgets"
  end

  # ------------------------------------------------------------------
  # JSON serialisation: the spec must round-trip through JSON.
  # Catches non-serialisable values (e.g. Procs, classes) that might
  # leak through from api_serializer attribute metadata.
  # ------------------------------------------------------------------

  test "spec round-trips through JSON cleanly" do
    json = JSON.pretty_generate(@spec)
    parsed = JSON.parse(json, symbolize_names: true)
    assert_equal "Dummy API", parsed[:info][:title]
    assert parsed[:paths].key?(:"/posts")

    # Optional artefact: dump for human inspection. tmp/ is in .gitignore.
    out = File.expand_path("../../tmp/dummy_openapi.json", __dir__)
    FileUtils.mkdir_p(File.dirname(out))
    File.write(out, json)
  end
end
