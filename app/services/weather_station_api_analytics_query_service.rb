class WeatherStationApiAnalyticsQueryService
  # Queries weather data in the same pattern as AnalyticsQueryService,
  # so the frontend can merge weather series alongside PLC measurement series.

  # Returns hourly aggregations at a weather location.
  #
  # @param weather_station_api_location_id [Integer]
  # @param start_date [Date]
  # @param end_date [Date]
  # @return [Hash] { weather_station_api_metric_id => [{ date:, hour:, min_value:, max_value:, avg_value:, sum_value:, sample_count: }] }
  def self.hourly(weather_station_api_location_id, start_date, end_date)
    aggregations = WeatherStationApiHourlyAggregation
      .where(weather_station_api_location_id: weather_station_api_location_id)
      .where(date: start_date..end_date)
      .order(:hour)
      .includes(:weather_station_api_metric)

    grouped = aggregations.group_by(&:weather_station_api_metric_id)

    { aggregations: grouped }
  end

  # Returns raw values for a short time window (max 24 hours).
  #
  # @param weather_station_api_location_id [Integer]
  # @param start_time [Time]
  # @param end_time [Time]
  # @return [Hash] { weather_station_api_metric_id => [{ sample_time:, value:, scaled_value: }] }
  def self.raw(weather_station_api_location_id, start_time, end_time)
    # Enforce 24-hour limit
    if end_time - start_time > 24.hours
      end_time = start_time + 24.hours
    end

    raw_values = WeatherStationApiRawValue
      .where(weather_station_api_location_id: weather_station_api_location_id)
      .where(sample_time: start_time..end_time)
      .order(:sample_time)

    grouped = raw_values.group_by(&:weather_station_api_metric_id)

    { raw_values: grouped }
  end

  # Returns the latest reading per metric for a weather location.
  # Useful for live data display.
  #
  # @param weather_station_api_location_id [Integer]
  # @return [Hash] { weather_station_api_metric_id => { value:, scaled_value:, sample_time: } }
  def self.latest(weather_station_api_location_id)
    # Subquery for max sample_time per metric
    latest_times = WeatherStationApiRawValue
      .where(weather_station_api_location_id: weather_station_api_location_id)
      .group(:weather_station_api_metric_id)
      .select(:weather_station_api_metric_id, "MAX(sample_time) AS max_sample_time")

    # Join back to get full records
    raw_values = WeatherStationApiRawValue
      .joins("INNER JOIN (#{latest_times.to_sql}) AS lt ON weather_station_api_raw_values.weather_station_api_metric_id = lt.weather_station_api_metric_id AND weather_station_api_raw_values.sample_time = lt.max_sample_time")
      .where(weather_station_api_location_id: weather_station_api_location_id)
      .includes(:weather_station_api_metric)
  end
end
