class WeatherStationApiHourlyAggregationService
  LOCATION_BATCH_SIZE = 50

  def self.call(**args)
    new(**args).call
  end

  def initialize(weather_station_api_location_ids: nil, now: Time.current)
    @weather_station_api_location_ids = weather_station_api_location_ids
    @current_hour = now.utc.beginning_of_hour
  end

  def call
    processed = 0
    errors = []

    eligible_locations.find_in_batches(batch_size: LOCATION_BATCH_SIZE) do |batch|
      result = process_batch(batch)
      processed += result[:processed]
      errors.concat(result[:errors])
    end

    { processed: processed, errors: errors }
  end

  private
    def eligible_locations
      scope = WeatherStationApiLocation.where(active: true)

      if @weather_station_api_location_ids
        scope = scope.where(id: @weather_station_api_location_ids)
      end

      scope
    end

    # ── Phase 1: Detect start times ───────────────────────────────────

    def detect_start_times(location_ids)
      latest_aggs = WeatherStationApiHourlyAggregation
        .where(weather_station_api_location_id: location_ids)
        .group(:weather_station_api_location_id)
        .maximum(:hour_timestamp)

      start_times = {}
      location_ids_without_aggs = []
      location_ids.each do |loc_id|
        if latest_aggs[loc_id]
          start_times[loc_id] = latest_aggs[loc_id].utc
        else
          location_ids_without_aggs << loc_id
        end
      end

      if location_ids_without_aggs.any?
        earliest_samples = WeatherStationApiRawValue
          .where(weather_station_api_location_id: location_ids_without_aggs)
          .group(:weather_station_api_location_id)
          .minimum(:sample_time)

        earliest_samples.each do |loc_id, sample_time|
          start_times[loc_id] = sample_time.utc.beginning_of_hour
        end
      end

      start_times
    end

    # ── Phase 2: Process a batch ──────────────────────────────────────

    def process_batch(locations)
      processed = 0
      errors = []

      location_ids = locations.map(&:id)
      start_times = detect_start_times(location_ids)

      if start_times.empty?
        return { processed: 0, errors: [] }
      end

      locations_by_start = start_times
        .group_by { |_, time| time }
        .transform_values { |pairs| pairs.map(&:first) }

      locations_by_start.each do |since_time, loc_ids|
        begin
          count = aggregate_since(loc_ids, since_time)
          processed += count
        rescue => e
          loc_ids.each do |loc_id|
            errors << { weather_station_api_location_id: loc_id, error: e.message }
          end
          Rails.logger.error(
            "[WeatherStationApiHourlyAggregation] Batch failed since #{since_time} " \
            "for #{loc_ids.size} locations: #{e.message}"
          )
        end
      end

      { processed: processed, errors: errors }
    end

    # ── Phase 3: Aggregate + upsert ──────────────────────────────────

    def aggregate_since(location_ids, since_time)
      end_time = @current_hour + 1.hour

      hour_format = Arel.sql("DATE_FORMAT(sample_time, '%Y-%m-%d %H:00:00')")
      raw_groups = WeatherStationApiRawValue
        .where(weather_station_api_location_id: location_ids)
        .where(sample_time: since_time...end_time)
        .group(
          :weather_station_api_location_id,
          :weather_station_api_metric_id,
          hour_format
        )
        .pluck(
          :weather_station_api_location_id,
          :weather_station_api_metric_id,
          hour_format,
          Arel.sql("MIN(scaled_value)"),
          Arel.sql("MAX(scaled_value)"),
          Arel.sql("AVG(scaled_value)"),
          Arel.sql("SUM(scaled_value)"),
          Arel.sql("COUNT(*)")
        )
      if raw_groups.empty?
        return 0
      end

      now = Time.current
      rows = raw_groups.map do |loc_id, metric_id, hour_timestamp, min_val, max_val, avg_val, sum_val, count|
        {
          weather_station_api_location_id: loc_id,
          weather_station_api_metric_id: metric_id,
          hour_timestamp: hour_timestamp,
          min_value: min_val,
          max_value: max_val,
          avg_value: avg_val,
          sum_value: sum_val,
          sample_count: count,
          created_at: now,
          updated_at: now
        }
      end

      rows.each_slice(500) do |chunk|
        batch_upsert(chunk)
      end

      rows.size
    end

    # ── MySQL batch upsert ────────────────────────────────────────────

    def batch_upsert(rows)
      if rows.empty?
        return
      end

      columns = rows.first.keys
      col_names = columns.map { |c| "`#{c}`" }.join(", ")

      value_sets = rows.map do |row|
        placeholders = row.values.map { "?" }
        "(#{placeholders.join(', ')})"
      end

      all_values = rows.flat_map(&:values)

      update_cols = columns - %i[weather_station_api_location_id weather_station_api_metric_id hour_timestamp created_at]
      update_clause = update_cols.map { |c| "`#{c}` = VALUES(`#{c}`)" }.join(", ")

      sql = <<~SQL
        INSERT INTO `weather_station_api_hourly_aggregations` (#{col_names})
        VALUES #{value_sets.join(', ')}
        ON DUPLICATE KEY UPDATE #{update_clause}
      SQL

      sanitized = ActiveRecord::Base.sanitize_sql_array([sql, *all_values])
      ActiveRecord::Base.connection.execute(sanitized)
    end
end
