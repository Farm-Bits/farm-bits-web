class WeatherStationApiAnalyticsQueryService
  # Queries weather data in the same pattern as AnalyticsQueryService,
  # so the frontend can merge weather series alongside PLC measurement series.

  # Returns hourly aggregations for given metrics at a weather location.
  #
  # @param weather_station_api_location_id [Integer]
  # @param metric_ids [Array<Integer>] WeatherStationApiMetric IDs
  # @param start_date [Date]
  # @param end_date [Date]
  # @return [Hash] { weather_station_api_metric_id => [{ hour:, min_value:, max_value:, avg_value:, sum_value:, sample_count: }] }
  def self.hourly(weather_station_api_location_id, metric_ids, start_date, end_date)
    aggregations = WeatherStationApiHourlyAggregation
      .where(weather_station_api_location_id: weather_station_api_location_id)
      .where(weather_station_api_metric_id: metric_ids)
      .where(hour: start_date.beginning_of_day..end_date.end_of_day)
      .order(:hour)

    result = {}
    metrics = WeatherStationApiMetric.where(id: metric_ids).index_by(&:id)

    aggregations.each do |agg|
      metric = metrics[agg.weather_station_api_metric_id]
      result[agg.weather_station_api_metric_id] ||= []

      # Use the primary value based on aggregation type
      primary_value = case metric&.aggregation
      when 'sum'
        agg.sum_value
      when 'min'
        agg.min_value
      when 'max'
        agg.max_value
      else
        agg.avg_value
      end

      result[agg.weather_station_api_metric_id] << {
        hour: agg.hour,
        value: primary_value,
        min_value: agg.min_value,
        max_value: agg.max_value,
        avg_value: agg.avg_value,
        sum_value: agg.sum_value,
        sample_count: agg.sample_count
      }
    end

    result
  end

  # Returns raw values for a short time window (max 24 hours).
  #
  # @param weather_station_api_location_id [Integer]
  # @param metric_ids [Array<Integer>] WeatherStationApiMetric IDs
  # @param start_time [Time]
  # @param end_time [Time]
  # @return [Hash] { weather_station_api_metric_id => [{ sample_time:, value:, scaled_value: }] }
  def self.raw(weather_station_api_location_id, metric_ids, start_time, end_time)
    # Enforce 24-hour limit
    if end_time - start_time > 24.hours
      end_time = start_time + 24.hours
    end

    raw_values = WeatherStationApiRawValue
      .where(weather_station_api_location_id: weather_station_api_location_id)
      .where(weather_station_api_metric_id: metric_ids)
      .where(sample_time: start_time..end_time)
      .order(:sample_time)

    result = {}

    raw_values.each do |rv|
      result[rv.weather_station_api_metric_id] ||= []
      result[rv.weather_station_api_metric_id] << {
        sample_time: rv.sample_time,
        value: rv.value,
        scaled_value: rv.scaled_value
      }
    end

    result
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

    result = {}

    raw_values.each do |rv|
      result[rv.weather_station_api_metric_id] = {
        value: rv.value,
        scaled_value: rv.scaled_value,
        sample_time: rv.sample_time
      }
    end

    result
  end
end
