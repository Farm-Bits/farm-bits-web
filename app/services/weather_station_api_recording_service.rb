class WeatherStationApiRecordingService
  # Processes normalized readings from a weather provider and stores them.
  #
  # @param weather_station_api_location [WeatherStationApiLocation]
  # @param readings [Array<Hash>] Each: { metric_key:, value:, sample_time: }
  # @param slot_time [Time] The time slot for which these readings are being recorded
  # @return [Integer] Number of records inserted
  def self.record(weather_station_api_location, readings, slot_time:)
    if readings.blank?
      return 0
    end

    metrics = WeatherStationApiMetric.all.index_by(&:key)
    now = Time.current

    rows = []

    readings.each do |reading|
      metric = metrics[reading[:metric_key]]

      if metric.nil?
        next
      end

      raw_value = reading[:value]
      scaled_value = metric.scale_value(raw_value)

      rows << {
        weather_station_api_location_id: weather_station_api_location.id,
        weather_station_api_metric_id: metric.id,
        value: raw_value,
        scaled_value: scaled_value,
        sample_time: reading[:sample_time]
      }
    end

    if rows.blank?
      return 0
    end

    # insert_all skips duplicates based on unique index
    result = WeatherStationApiRawValue.insert_all(rows)

    weather_station_api_location.update_columns(last_fetched_at: slot_time)

    result.count
  end
end
