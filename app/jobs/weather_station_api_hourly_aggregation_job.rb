class WeatherStationApiHourlyAggregationJob
  include Sidekiq::Job
  sidekiq_options queue: 'low', retry: 3

  def perform(weather_station_api_location_id = nil)
    args = {}

    if weather_station_api_location_id.present?
      args[:weather_station_api_location_ids] = [weather_station_api_location_id]
    end

    result = WeatherStationApiHourlyAggregationService.call(**args)

    if result[:errors].any?
      Rails.logger.warn(
        "[WeatherStationApiHourlyAggregationJob] Completed with #{result[:errors].size} error(s). " \
        "Processed: #{result[:processed]}. Errors: #{result[:errors].inspect}"
      )
      Bugsnag.notify("WeatherStationApiHourlyAggregationJob completed with errors") do |report|
        report.severity = 'warning'
        report.add_metadata(:hourly_aggregation, {
          processed: result[:processed],
          errors: result[:errors]
        })
      end
    end
  end
end
