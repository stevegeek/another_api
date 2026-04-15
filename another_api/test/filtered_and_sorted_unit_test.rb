# frozen_string_literal: true

require "test_helper"

# Unit test for FilteredAndSorted#bind_filter_context — the arity-2 transform
# rebinding branch is hard to exercise from a real HTTP request because it
# needs both an arity-2 transform proc on a schema attribute *and* a non-empty
# filter_request_context on the controller.
class AnotherApi::FilteredAndSortedUnitTest < Minitest::Test
  # Tiny controller subclass that includes the concern. The concern uses
  # rescue_from in its `included` block, so it needs an ActiveSupport::Rescuable
  # host — ActionController::API gives us exactly that.
  class Host < ::ActionController::API
    include AnotherApi::FilteredAndSorted

    attr_accessor :ctx

    def filter_request_context
      ctx
    end
  end

  def test_bind_filter_context_returns_mappings_unchanged_when_context_is_empty
    host = Host.new
    host.ctx = {}
    mapping = ApiSerializer::QueryableConfig.new(transform: ->(_, _) { :rebound })
    result = host.send(:bind_filter_context, {field: mapping})
    # No rebinding because ctx is empty.
    assert_same mapping, result[:field]
  end

  def test_bind_filter_context_rebinds_arity_2_transform_to_arity_1_with_baked_context
    host = Host.new
    host.ctx = {requestor: "tests"}
    mapping = ApiSerializer::QueryableConfig.new(
      filter: true,
      transform: ->(api_value, context) { "#{api_value}::#{context[:requestor]}" }
    )
    result = host.send(:bind_filter_context, {field: mapping})
    rebound = result[:field]
    refute_same mapping, rebound
    assert_equal 1, rebound.transform.arity
    assert_equal "abc::tests", rebound.transform.call("abc")
  end

  def test_bind_filter_context_leaves_non_arity_2_transforms_alone
    host = Host.new
    host.ctx = {anything: 1}
    one_arg_mapping = ApiSerializer::QueryableConfig.new(filter: true, transform: ->(v) { v.upcase })
    result = host.send(:bind_filter_context, {field: one_arg_mapping})
    assert_same one_arg_mapping, result[:field]
  end
end
