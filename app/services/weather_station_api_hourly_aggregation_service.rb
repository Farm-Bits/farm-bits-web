class WeatherStationApiHourlyAggregationService
  # Aggregates weather raw values into hourly aggregations for a given location.
  # Uses the metric's aggregation type to determine which fields are primary.
  #
  # @param weather_station_api_location [WeatherStationApiLocation]
  # @param from_hour [Time] Start hour (UTC, truncated to hour)
  # @param to_hour [Time] End hour (UTC, truncated to hour)
  def self.aggregate(weather_station_api_location, from_hour:, to_hour:)
    metrics = WeatherStationApiMetric.all.index_by(&:id)

    # Query raw values grouped by metric and hour
    raw_groups = WeatherStationApiRawValue
      .where(weather_station_api_location: weather_station_api_location)
      .where(sample_time: from_hour..to_hour)
      .group(:weather_station_api_metric_id, "DATE_FORMAT(sample_time, '%Y-%m-%d %H:00:00')")
      .pluck(
        :weather_station_api_metric_id,
        Arel.sql("DATE_FORMAT(sample_time, '%Y-%m-%d %H:00:00')"),
        Arel.sql("MIN(scaled_value)"),
        Arel.sql("MAX(scaled_value)"),
        Arel.sql("AVG(scaled_value)"),
        Arel.sql("SUM(scaled_value)"),
        Arel.sql("COUNT(*)")
      )

    if raw_groups.blank?
      return 0
    end

    now = Time.current
    rows = raw_groups.map do |metric_id, hour_str, min_val, max_val, avg_val, sum_val, count|
      date_str, hour_str = hour_str.split(' ')
      hour = hour_str.to_i
      {
        weather_station_api_location_id: weather_station_api_location.id,
        weather_station_api_metric_id: metric_id,
        date: date_str,
        hour: hour,
        min_value: min_val,
        max_value: max_val,
        avg_value: avg_val,
        sum_value: sum_val,
        sample_count: count,
        created_at: now,
        updated_at: now
      }
    end

    # MySQL upsert - update existing aggregations if re-run
    sql = build_upsert_sql(rows)
    ActiveRecord::Base.connection.execute(sql)

    rows.size
  end

  private
    def self.build_upsert_sql(rows)
      columns = [:weather_station_api_location_id, :weather_station_api_metric_id, :date, :hour, :min_value, :max_value, :avg_value, :sum_value, :sample_count, :created_at, :updated_at]

      values_sql = rows.map do |row|
        values = columns.map do |col|
          val = row[col]
          if val.nil?
            "NULL"
          elsif val.is_a?(Numeric)
            val.to_s
          else
            ActiveRecord::Base.connection.quote(val)
          end
        end
        "(#{values.join(', ')})"
      end.join(",\n")

      quoted_columns = columns.map { |c| "`#{c}`" }.join(', ')

      <<~SQL
        INSERT INTO `weather_station_api_hourly_aggregations` (#{quoted_columns})
        VALUES #{values_sql}
        ON DUPLICATE KEY UPDATE
          `min_value` = VALUES(`min_value`),
          `max_value` = VALUES(`max_value`),
          `avg_value` = VALUES(`avg_value`),
          `sum_value` = VALUES(`sum_value`),
          `sample_count` = VALUES(`sample_count`),
          `updated_at` = VALUES(`updated_at`)
      SQL
    end
end
