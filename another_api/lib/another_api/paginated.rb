module AnotherApi
  module Paginated
    def parsed_page_param
      page = sanitise_query_param(params[:page], max_length: 20)&.to_i || 1
      (page.is_a?(Numeric) && page.positive?) ? page : 1
    end

    def parsed_page_size_param(default_size: AnotherApi.configuration.default_page_size, max_page_size: AnotherApi.configuration.max_page_size)
      size = sanitise_query_param(params[:page_size], max_length: 5)&.to_i || default_size
      size_is_positive = size.is_a?(Numeric) && size.positive?
      size = max_page_size if size_is_positive && size > max_page_size
      size_is_positive ? size : default_size
    end

    def parsed_page_options
      {
        page: parsed_page_param,
        page_size: parsed_page_size_param
      }.compact_blank
    end
  end
end
