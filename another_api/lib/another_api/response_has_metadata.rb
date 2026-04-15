require "active_support/core_ext/numeric/time"

module AnotherApi
  module ResponseHasMetadata
    extend ActiveSupport::Concern

    RECOMMENDED_POLL_INTERVAL = 5.seconds

    def collection_response_metadata(query)
      total_count = query.total_count
      total_pages = total_count.fdiv(query.page_size).ceil
      {
        offset: query.offset_value,
        count: query.page_count,
        total_count:,
        total_pages:,
        has_more: total_pages > query.page,
        request_id: request.request_id,
        request_started_at: started_processing_request_at.iso8601,
        request_ended_at: Time.zone.now.iso8601,
        next_poll_at: RECOMMENDED_POLL_INTERVAL.from_now.iso8601
      }
    end

    def single_item_response_metadata
      {
        request_id: request.request_id,
        request_started_at: started_processing_request_at.iso8601,
        request_ended_at: Time.zone.now.iso8601,
        next_poll_at: RECOMMENDED_POLL_INTERVAL.from_now.iso8601
      }
    end
  end
end
