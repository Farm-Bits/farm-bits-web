class WeatherStationApiBackfillJob
  include Sidekiq::Job
  sidekiq_options queue: 'low'

  # Backfill historical weather data for a location.
  # IMS API supports fetching by date range.
  #
  # @param weather_station_api_location_id [Integer]
  # @param from_date [String] ISO date (e.g., "2025-01-01")
  # @param to_date [String] ISO date (e.g., "2025-02-25")
  def perform(weather_station_api_location_id, from_date, to_date)
    weather_station_api_location = WeatherStationApiLocation.find_by(id: weather_station_api_location_id)

    if weather_station_api_location.nil?
      Rails.logger.warn("[WeatherStationApiBackfillJob] Location #{weather_station_api_location_id} not found")
      return
    end

    from = Date.parse(from_date)
    to = Date.parse(to_date)

    # IMS API may have limits on range size, fetch in 7-day chunks
    current_from = from

    while current_from <= to
      current_to = [current_from + 6.days, to].min

      adapter = weather_station_api_location.provider_adapter
      readings = adapter.fetch_range(current_from, current_to)
      WeatherStationApiRecordingService.record(weather_station_api_location, readings)

      current_from = current_to + 1.day

      # Rate limit courtesy
      sleep(0.5)
    end

    # Run aggregation for the backfilled period
    from_hour = from.beginning_of_day
    to_hour = (to + 1.day).beginning_of_day
    WeatherStationApiHourlyAggregationService.aggregate(weather_station_api_location, from_hour: from_hour, to_hour: to_hour)
  rescue => e
    Rails.logger.error("[WeatherStationApiBackfillJob] Error for location #{weather_station_api_location_id}: #{e.class} - #{e.message}")
    raise
  end
end
