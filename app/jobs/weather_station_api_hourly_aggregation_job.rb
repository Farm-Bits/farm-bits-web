class WeatherStationApiHourlyAggregationJob
  include Sidekiq::Job
  queue_as :low
  sidekiq_options retry: 3

  # Aggregates the previous hour's raw values into hourly aggregations.
  # Run this at ~5 minutes past each hour to ensure all readings are in.
  def perform(weather_station_api_location_id = nil)
    previous_hour = 1.hour.ago.beginning_of_hour
    current_hour = Time.current.beginning_of_hour

    if weather_station_api_location_id.present?
      weather_station_api_location = WeatherStationApiLocation.find_by(id: weather_station_api_location_id)
      if weather_station_api_location.nil?
        Rails.logger.warn("[WeatherStationApiHourlyAggregationJob] Weather Station API Location #{weather_station_api_location_id} not found")
        return
      end
      aggregate_weather_station_api_location(weather_station_api_location, previous_hour, current_hour)
    else
      WeatherStationApiLocation.where(active: true).find_each do |weather_station_api_location|
        aggregate_weather_station_api_location(weather_station_api_location, previous_hour, current_hour)
      end
    end
  end

  private
    def aggregate_weather_station_api_location(weather_station_api_location, from_hour, to_hour)
      begin
        WeatherStationApiHourlyAggregationService.aggregate(
          weather_station_api_location,
          from_hour: from_hour,
          to_hour: to_hour
        )
      rescue => e
        Rails.logger.error(
          "[WeatherStationApiHourlyAggregationJob] Error aggregating location #{weather_station_api_location.id}: #{e.class} - #{e.message}"
        )
      end
    end
end
