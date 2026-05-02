# frozen_string_literal: true

require "test_helper"
require "another_api/openapi"

class AnotherApi::OpenAPI::PathBuilderTest < Minitest::Test
  def setup
    @prev = AnotherApi::OpenAPI.instance_variable_get(:@configuration)
    AnotherApi::OpenAPI.reset_configuration!
  end

  def teardown
    AnotherApi::OpenAPI.instance_variable_set(:@configuration, @prev)
  end

  def endpoint(action:, path: "/widgets", **overrides)
    {
      path: path,
      verb: verb_for(action),
      action: action.to_s,
      operation_id: "#{action}_widgets",
      tags: ["Widgets"],
      summary: action.to_s.capitalize,
      schema_ref: "WidgetFull",
      concerns: [],
      description: nil,
      custom_query_params: nil
    }.merge(overrides)
  end

  def verb_for(action)
    {index: "get", show: "get", create: "post", update: "patch", destroy: "delete"}.fetch(action)
  end

  # ------------------------------------------------------------------
  # Per-action response shapes
  # ------------------------------------------------------------------

  def test_index_response_envelopes_data_in_array_with_pagination_metadata
    paths = AnotherApi::OpenAPI::PathBuilder.new([endpoint(action: :index, concerns: [:paginated])]).build_all
    op = paths["/widgets"]["get"]
    body = op[:responses]["200"][:content]["application/json"][:schema]

    assert_equal "array", body[:properties][:data][:type]
    assert_equal "#/components/schemas/WidgetFull", body[:properties][:data][:items]["$ref"]
    assert_equal "#/components/schemas/PaginationMetadata", body[:properties][:metadata]["$ref"]
  end

  def test_show_response_returns_single_data_object_with_404
    paths = AnotherApi::OpenAPI::PathBuilder.new([endpoint(action: :show, path: "/widgets/:id")]).build_all
    op = paths["/widgets/{id}"]["get"]

    assert op[:responses]["200"]
    assert op[:responses]["404"], "show should advertise 404"
    body = op[:responses]["200"][:content]["application/json"][:schema]
    assert_equal "#/components/schemas/WidgetFull", body[:properties][:data]["$ref"]
  end

  def test_create_response_uses_201_status
    paths = AnotherApi::OpenAPI::PathBuilder.new([endpoint(action: :create)]).build_all
    op = paths["/widgets"]["post"]

    assert op[:responses]["201"], "create should return 201"
    refute op[:responses]["200"], "create should not return 200"
  end

  def test_update_response_returns_data_object
    paths = AnotherApi::OpenAPI::PathBuilder.new([endpoint(action: :update, path: "/widgets/:id")]).build_all
    op = paths["/widgets/{id}"]["patch"]

    assert op[:responses]["200"]
    body = op[:responses]["200"][:content]["application/json"][:schema]
    assert_equal "#/components/schemas/WidgetFull", body[:properties][:data]["$ref"]
  end

  def test_destroy_response_returns_message_only
    paths = AnotherApi::OpenAPI::PathBuilder.new([endpoint(action: :destroy, path: "/widgets/:id")]).build_all
    op = paths["/widgets/{id}"]["delete"]

    body = op[:responses]["200"][:content]["application/json"][:schema]
    assert body[:properties].key?(:message)
    refute body[:properties].key?(:data), "destroy should not include data"
  end

  def test_index_does_not_advertise_404
    paths = AnotherApi::OpenAPI::PathBuilder.new([endpoint(action: :index)]).build_all
    refute paths["/widgets"]["get"][:responses].key?("404"),
      "404 is not meaningful for collection index"
  end

  # ------------------------------------------------------------------
  # Request body
  # ------------------------------------------------------------------

  def test_create_with_known_input_schema_emits_ref
    pb = AnotherApi::OpenAPI::PathBuilder.new(
      [endpoint(action: :create)],
      known_schemas: ["WidgetCreateInput"]
    )
    op = pb.build_all["/widgets"]["post"]

    body_schema = op[:requestBody][:content]["application/json"][:schema]
    assert_equal "#/components/schemas/WidgetCreateInput", body_schema["$ref"]
    assert op[:requestBody][:required]
  end

  def test_create_without_known_input_schema_falls_back_to_object
    pb = AnotherApi::OpenAPI::PathBuilder.new([endpoint(action: :create)])
    op = pb.build_all["/widgets"]["post"]

    body_schema = op[:requestBody][:content]["application/json"][:schema]
    assert_equal "object", body_schema[:type]
  end

  def test_update_emits_update_input_request_body
    pb = AnotherApi::OpenAPI::PathBuilder.new(
      [endpoint(action: :update, path: "/widgets/:id")],
      known_schemas: ["WidgetUpdateInput"]
    )
    op = pb.build_all["/widgets/{id}"]["patch"]

    body_schema = op[:requestBody][:content]["application/json"][:schema]
    assert_equal "#/components/schemas/WidgetUpdateInput", body_schema["$ref"]
  end

  def test_index_does_not_emit_request_body
    pb = AnotherApi::OpenAPI::PathBuilder.new([endpoint(action: :index)])
    op = pb.build_all["/widgets"]["get"]
    refute op.key?(:requestBody)
  end

  def test_action_without_schema_ref_does_not_emit_request_body
    pb = AnotherApi::OpenAPI::PathBuilder.new([endpoint(action: :create, schema_ref: nil)])
    op = pb.build_all["/widgets"]["post"]
    refute op.key?(:requestBody)
  end

  # ------------------------------------------------------------------
  # Path parameters from :id-style segments
  # ------------------------------------------------------------------

  def test_path_parameters_extracted_from_colon_segments
    pb = AnotherApi::OpenAPI::PathBuilder.new(
      [endpoint(action: :show, path: "/widgets/:id/sub/:sub_id")]
    )
    op = pb.build_all["/widgets/{id}/sub/{sub_id}"]["get"]

    path_params = op[:parameters].select { |p| p[:in] == "path" }
    assert_equal ["id", "sub_id"], path_params.map { |p| p[:name] }
    path_params.each { |p| assert p[:required] }
  end

  # ------------------------------------------------------------------
  # custom_query_params
  # ------------------------------------------------------------------

  def test_custom_query_params_rendered_with_format_and_required
    pb = AnotherApi::OpenAPI::PathBuilder.new([
      endpoint(action: :index, custom_query_params: [
        {name: "delivery_date", type: "string", format: "date", required: true, description: "ISO8601"},
        {name: "min_price", type: "number"}
      ])
    ])
    op = pb.build_all["/widgets"]["get"]
    custom = op[:parameters].select { |p| p.is_a?(Hash) && %w[delivery_date min_price].include?(p[:name]) }

    assert_equal 2, custom.size
    delivery = custom.find { |p| p[:name] == "delivery_date" }
    assert delivery[:required]
    assert_equal "date", delivery[:schema][:format]
    assert_equal "ISO8601", delivery[:description]

    min_price = custom.find { |p| p[:name] == "min_price" }
    refute min_price[:required], "default required: false"
  end

  # ------------------------------------------------------------------
  # Concern parameter refs
  # ------------------------------------------------------------------

  def test_filter_on_deleted_concern_adds_deleted_parameter_to_index
    pb = AnotherApi::OpenAPI::PathBuilder.new(
      [endpoint(action: :index, concerns: [:filter_on_deleted])]
    )
    op = pb.build_all["/widgets"]["get"]
    refs = op[:parameters].map { |p| p["$ref"] }.compact

    assert_includes refs, "#/components/parameters/deleted"
  end

  def test_filter_on_active_concern_adds_active_parameter_to_index
    pb = AnotherApi::OpenAPI::PathBuilder.new(
      [endpoint(action: :index, concerns: [:filter_on_active])]
    )
    op = pb.build_all["/widgets"]["get"]
    refs = op[:parameters].map { |p| p["$ref"] }.compact

    assert_includes refs, "#/components/parameters/active"
  end

  def test_index_with_all_concerns_advertises_all_parameter_refs
    pb = AnotherApi::OpenAPI::PathBuilder.new([
      endpoint(action: :index, concerns: [:paginated, :filtered_and_sorted, :schema_configurable])
    ])
    op = pb.build_all["/widgets"]["get"]
    refs = op[:parameters].map { |p| p["$ref"] }.compact

    %w[page page_size variant filter sort].each do |name|
      assert_includes refs, "#/components/parameters/#{name}"
    end
  end

  def test_index_with_no_concerns_advertises_no_pagination_filter_sort_variant
    pb = AnotherApi::OpenAPI::PathBuilder.new([endpoint(action: :index)])
    op = pb.build_all["/widgets"]["get"]
    refs = op[:parameters].map { |p| p["$ref"] }.compact

    %w[page page_size variant filter sort].each do |name|
      refute_includes refs, "#/components/parameters/#{name}",
        "Index without concerns should not advertise #{name}"
    end
  end

  def test_index_with_only_paginated_concern_advertises_only_pagination_refs
    pb = AnotherApi::OpenAPI::PathBuilder.new([endpoint(action: :index, concerns: [:paginated])])
    op = pb.build_all["/widgets"]["get"]
    refs = op[:parameters].map { |p| p["$ref"] }.compact

    assert_includes refs, "#/components/parameters/page"
    assert_includes refs, "#/components/parameters/page_size"
    refute_includes refs, "#/components/parameters/filter"
    refute_includes refs, "#/components/parameters/variant"
  end

  def test_index_with_only_filtered_and_sorted_advertises_only_filter_sort
    pb = AnotherApi::OpenAPI::PathBuilder.new([endpoint(action: :index, concerns: [:filtered_and_sorted])])
    op = pb.build_all["/widgets"]["get"]
    refs = op[:parameters].map { |p| p["$ref"] }.compact

    assert_includes refs, "#/components/parameters/filter"
    assert_includes refs, "#/components/parameters/sort"
    refute_includes refs, "#/components/parameters/page"
    refute_includes refs, "#/components/parameters/variant"
  end

  def test_show_does_not_emit_pagination_parameter_refs
    pb = AnotherApi::OpenAPI::PathBuilder.new([endpoint(action: :show, path: "/widgets/:id")])
    op = pb.build_all["/widgets/{id}"]["get"]
    refs = op[:parameters].map { |p| p["$ref"] }.compact

    refute_includes refs, "#/components/parameters/page"
    refute_includes refs, "#/components/parameters/filter"
  end

  # ------------------------------------------------------------------
  # Error responses
  # ------------------------------------------------------------------

  def test_error_responses_use_configured_error_content
    AnotherApi::OpenAPI.configuration.error_response_content = {"application/custom" => {schema: {type: "string"}}}
    pb = AnotherApi::OpenAPI::PathBuilder.new([endpoint(action: :show, path: "/widgets/:id")])
    op = pb.build_all["/widgets/{id}"]["get"]

    assert op[:responses]["400"][:content].key?("application/custom")
    assert op[:responses]["401"][:content].key?("application/custom")
    assert op[:responses]["403"][:content].key?("application/custom")
  end
end
