module AnotherApi
  module FilteredAndSorted
    extend ActiveSupport::Concern

    included do
      rescue_from ::ApiQueryLanguage::Errors::InvalidFieldError, ::ApiQueryLanguage::Errors::InvalidFieldValueError do |e|
        Rails.logger.info("[another_api] bad filter/sort request: #{e.class}: #{e.message}")
        respond_to do |format|
          format.json { render json: json_error_body("bad_request", "Bad request. Something is wrong with your filtering or sorting query expression, please check that the field names are valid for the given endpoint."), status: :bad_request }
          format.any { head :bad_request }
        end
      end

      rescue_from ::ApiQueryLanguage::Errors::UnsupportedFieldTypeError, ::ApiQueryLanguage::Errors::UnsupportedCollectionFieldTypeError do |e|
        Rails.logger.info("[another_api] bad filter/sort request: #{e.class}: #{e.message}")
        respond_to do |format|
          format.json { render json: json_error_body("bad_request", "Bad request. We are unable to apply your filtering or sorting query expression, please check that the field names are valid and supported for the given endpoint. If you expect the field values to work, please contact support to see if we can help you out."), status: :bad_request }
          format.any { head :bad_request }
        end
      end
    end

    def apply_filter_and_sort(query, default_sort: nil, default_filter: nil)
      query = apply_filter(query, default_filter:)
      apply_sort(query, default_sort:)
    end

    def apply_filter(query, default_filter: nil)
      filterer = parsed_filter_param(query)
      if filterer
        filterer.apply_to(query)
      elsif default_filter.present?
        default_filter.call(query)
      else
        query
      end
    end

    def apply_sort(query, default_sort: nil)
      sorter = parsed_sort_param(query)
      if sorter
        sorter.apply_to(query)
      elsif default_sort.present?
        default_sort.call(query)
      else
        query
      end
    end

    private

    def parsed_filter_param(query)
      return if params[:filter].blank?

      mappings = filterable_schema_for(query.model).filtering_mapped_attributes
      mappings = bind_filter_context(mappings)

      ::ApiQueryLanguage::ActiveRecord::Filtering::FilterExpression.new(
        sanitise_query_param(params[:filter], max_length: 1000),
        mappings
      )
    rescue ApiQueryLanguage::Errors::Error => e
      raise AnotherApi::BadRequestError, "Invalid filter query: #{e.message}"
    end

    def parsed_sort_param(query)
      return if params[:sort].blank?

      ::ApiQueryLanguage::ActiveRecord::Sorting::SortExpression.new(
        sanitise_query_param(params[:sort], max_length: 1000),
        filterable_schema_for(query.model).sorting_mapped_attributes
      )
    rescue ApiQueryLanguage::Errors::Error => e
      raise AnotherApi::BadRequestError, "Invalid sort query: #{e.message}"
    end

    def bind_filter_context(mappings)
      ctx = filter_request_context
      return mappings if ctx.blank?

      mappings.transform_values do |v|
        next v unless v.respond_to?(:transform) && v.transform.is_a?(Proc) && v.transform.arity == 2
        v.with(transform: ->(api_value) { v.transform.call(api_value, ctx) })
      end
    end

    def filter_request_context
      {}
    end

    def filterable_schema_for(_model)
      api_schema_class.fetch_variant(:serializer, false, :full).serialization
    end
  end
end
