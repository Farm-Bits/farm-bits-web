class HourlyAggregationJob
  include Sidekiq::Job
  queue_as :low
  sidekiq_options retry: 3

  def perform(measurement_point_ids = nil)
    result = HourlyAggregationService.call(
      measurement_point_ids: measurement_point_ids
    )

    if result[:errors].any?
      Rails.logger.warn(
        "[HourlyAggregationJob] Completed with #{result[:errors].size} error(s). " \
        "Processed: #{result[:processed]}. Errors: #{result[:errors].inspect}"
      )
    end
  end
end
