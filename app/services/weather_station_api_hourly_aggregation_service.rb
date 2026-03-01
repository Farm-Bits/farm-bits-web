class WeatherStationApiHourlyAggregationService
  LOCATION_BATCH_SIZE = 50

  def self.call(**args)
    new(**args).call
  end

  # @param weather_station_api_location_ids [Array<Integer>, nil] optional filter
  # @param now [Time] override for testing; defaults to Time.current
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

    # ── Phase 1: Detect the earliest hour we need to aggregate from ────

    # For each location, find where to start:
    # - If aggregations exist: re-aggregate from the latest aggregated hour
    # - If no aggregations: start from the earliest raw value
    # Returns { location_id => start_time (UTC) }
    def detect_start_times(location_ids)
      # 1) Latest aggregation per location — single query
      latest_aggs = WeatherStationApiHourlyAggregation
        .where(weather_station_api_location_id: location_ids)
        .group(:weather_station_api_location_id)
        .pluck(
          :weather_station_api_location_id,
          Arel.sql("MAX(CONCAT(`date`, ' ', LPAD(`hour`, 2, '0')))")
        ).to_h

      start_times = {}
      location_ids_without_aggs = []
      location_ids.each do |loc_id|
        if latest_aggs[loc_id]
          date_str, hour_str = latest_aggs[loc_id].split(" ")
          parsed = Date.parse(date_str)
          start_times[loc_id] = Time.utc(parsed.year, parsed.month, parsed.day, hour_str.to_i)
        else
          location_ids_without_aggs << loc_id
        end
      end

      # 2) Earliest raw value per location (only for those without any aggregation)
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

    # ── Phase 2: Process a batch ────────────────────────────────────────

    # Groups locations by their start time and aggregates each group
    # in a single SQL query across all hours at once.
    def process_batch(locations)
      processed = 0
      errors = []

      location_ids = locations.map(&:id)
      start_times = detect_start_times(location_ids)

      if start_times.empty?
        return { processed: 0, errors: [] }
      end

      # Group locations by start_time so those needing the same range
      # can be aggregated together in a single query.
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

    # ── Phase 3: Aggregate + upsert ────────────────────────────────────

    # Single SQL query: aggregate all raw values for the given locations
    # from since_time to current_hour, grouped by (location, metric, date, hour).
    # This replaces the hour-by-hour iteration with one database pass.
    def aggregate_since(location_ids, since_time)
      end_time = @current_hour + 1.hour

      raw_groups = WeatherStationApiRawValue
        .where(weather_station_api_location_id: location_ids)
        .where(sample_time: since_time...end_time)
        .group(
          :weather_station_api_location_id,
          :weather_station_api_metric_id,
          Arel.sql("DATE(sample_time)"),
          Arel.sql("HOUR(sample_time)")
        )
        .pluck(
          :weather_station_api_location_id,
          :weather_station_api_metric_id,
          Arel.sql("DATE(sample_time)"),
          Arel.sql("HOUR(sample_time)"),
          Arel.sql("AVG(scaled_value)"),
          Arel.sql("SUM(scaled_value)"),
          Arel.sql("COUNT(*)")
        )

      if raw_groups.empty?
        return 0
      end

      now = Time.current
      rows = raw_groups.map do |loc_id, metric_id, date, hour, avg_val, sum_val, count|
        {
          weather_station_api_location_id: loc_id,
          weather_station_api_metric_id: metric_id,
          date: date,
          hour: hour,
          avg_value: avg_val,
          sum_value: sum_val,
          sample_count: count,
          created_at: now,
          updated_at: now
        }
      end

      # Upsert in chunks to avoid exceeding MySQL max_allowed_packet
      rows.each_slice(500) do |chunk|
        batch_upsert(chunk)
      end

      rows.size
    end

    # ── MySQL batch upsert ─────────────────────────────────────────────

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

      # Update everything except the unique key columns and created_at
      update_cols = columns - %i[weather_station_api_location_id weather_station_api_metric_id date hour created_at]
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
