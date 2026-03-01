class HourlyAggregationJob
  include Sidekiq::Job
  sidekiq_options queue: 'low', retry: 3

  def perform(measurement_point_ids = nil)
    result = HourlyAggregationService.call(
      measurement_point_ids: measurement_point_ids
    )

    if result[:errors].any?
      Rails.logger.warn(
        "[HourlyAggregationJob] Completed with #{result[:errors].size} error(s). " \
        "Processed: #{result[:processed]}. Errors: #{result[:errors].inspect}"
      )
      Bugsnag.notify("HourlyAggregationJob completed with errors") do |report|
        report.severity = 'warning'
        report.add_metadata(:hourly_aggregation, {
          processed: result[:processed],
          errors: result[:errors]
        })
      end
    end
  end
end
