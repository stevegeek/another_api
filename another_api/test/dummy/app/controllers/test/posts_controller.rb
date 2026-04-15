# frozen_string_literal: true

module Test
  class PostsController < AnotherApi::BaseController
    include AnotherApi::FilteredAndSorted
    include AnotherApi::ParamDeserializer
    include AnotherApi::Paginated
    include Dry::Monads[:result]

    def index
      api_respond_to_json do
        authorize! with: Test::PostsPolicy

        scope = ::Post.all
        scope = apply_filter_and_sort(scope)
        records = scope.limit(parsed_page_size_param).offset((parsed_page_param - 1) * parsed_page_size_param)

        Success(
          data: records.map { |p| p.serialization(model_name: "Post").serialize(:default).as_json },
          page: parsed_page_param,
          page_size: parsed_page_size_param
        )
      end
    end

    # Variant of index that supplies default_filter / default_sort callables —
    # exercised by tests to cover the "no params, fall back to defaults" branch
    # in FilteredAndSorted#apply_filter and #apply_sort.
    def defaults_index
      api_respond_to_json do
        authorize! with: Test::PostsPolicy, to: :index?
        scope = apply_filter_and_sort(::Post.all,
          default_filter: ->(q) { q.where(title: "Default") },
          default_sort: ->(q) { q.order(id: :desc) })
        Success(data: scope.map { |p| {id: p.id, title: p.title} })
      end
    end

    def show
      api_respond_to_json do
        post = ::Post.find_by(id: params[:id])
        if post
          authorize! post, with: Test::PostsPolicy
          # Schema only defines :default; the helper falls back to :full,
          # which doesn't exist — so we just take the parse_requested_variant_for
          # result if it's a known variant, otherwise :default.
          requested = parse_requested_variant_for(CoreSchemas::V2::Post)
          variant = CoreSchemas::V2::Post.variant?(requested) ? requested : :default
          Success(
            data: post.serialization(model_name: "Post").serialize(variant).as_json,
            metadata: single_item_response_metadata
          )
        else
          Failure(:not_found)
        end
      end
    end

    def create
      api_respond_to_json do
        authorize! with: Test::PostsPolicy
        input = deserialize_params(CoreSchemas::V2::Post, :create)
        record = ::Post.new(title: input.title, body: input.body, bearer: current_bearer)
        if record.save
          Success(data: record.serialization(model_name: "Post").serialize(:default).as_json, status: :created)
        else
          Failure[:validation_error, record]
        end
      end
    end

    private

    # FilteredAndSorted's default `filterable_schema_for` calls `api_schema_class`
    # — providing this lets us cover the default implementation rather than
    # overriding `filterable_schema_for` ourselves.
    def api_schema_class
      Class.new do
        def self.fetch_variant(_, _, _)
          CoreSchemas::V2::Post.fetch_variant(:serializer, false, :default)
        end
      end
    end

    # Note: filter_request_context is left at the gem default ({}). This both
    # exercises the default body and makes bind_filter_context fall through
    # the early-return branch.
  end
end
