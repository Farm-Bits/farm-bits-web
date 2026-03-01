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

    # ── Phase 1: Gap detection ──────────────────────────────────────────

    # For a batch of locations, determine each one's start_hour.
    # Returns { location_id => start_hour_time }
    def detect_start_hours(location_ids)
      # 1) Latest aggregation per location — single query
      latest_aggs = WeatherStationApiHourlyAggregation
        .where(weather_station_api_location_id: location_ids)
        .group(:weather_station_api_location_id)
        .pluck(
          :weather_station_api_location_id,
          Arel.sql("MAX(CONCAT(date, ' ', LPAD(hour, 2, '0')))")
        ).to_h
      # => { location_id => "2026-02-17 14", ... }

      start_hours = {}
      location_ids_without_aggs = []
      location_ids.each do |loc_id|
        if latest_aggs[loc_id]
          date_str, hour_str = latest_aggs[loc_id].split(" ")
          parsed = Date.parse(date_str)
          start_hours[loc_id] = Time.utc(parsed.year, parsed.month, parsed.day, hour_str.to_i)
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
          start_hours[loc_id] = sample_time.utc.beginning_of_hour
        end
      end

      start_hours
    end

    # Build { location_id => [hour_start, ...] } for a batch.
    def build_hour_plan(location_ids)
      start_hours = detect_start_hours(location_ids)
      if start_hours.empty?
        return {}
      end

      plan = {}
      start_hours.each do |loc_id, start_hour|
        hours = []
        h = start_hour
        while h <= @current_hour
          hours << h
          h += 1.hour
        end

        if hours.any?
          plan[loc_id] = hours
        end
      end

      plan
    end

    # ── Phase 2: Process a batch ────────────────────────────────────────

    def process_batch(locations)
      processed = 0
      errors = []

      location_ids = locations.map(&:id)
      plan = build_hour_plan(location_ids)

      if plan.empty?
        return { processed: 0, errors: [] }
      end

      # Collect all unique hours across this batch, sorted chronologically
      all_hours = plan.values.flatten.uniq.sort

      # Process one hour at a time across all locations that need it
      all_hours.each do |hour_start|
        loc_ids_for_hour = plan.filter_map { |loc_id, hours| loc_id if hours.include?(hour_start) }

        if loc_ids_for_hour.empty?
          next
        end

        begin
          count = aggregate_hour_batch(loc_ids_for_hour, hour_start)
          processed += count
        rescue => e
          loc_ids_for_hour.each do |loc_id|
            errors << { weather_station_api_location_id: loc_id, hour: hour_start, error: e.message }
          end
          Rails.logger.error(
            "[WeatherStationApiHourlyAggregation] Batch failed for hour #{hour_start}: #{e.message}"
          )
        end
      end

      { processed: processed, errors: errors }
    end

    # ── Phase 3: Aggregate + upsert ────────────────────────────────────

    # Fetch raw values for multiple locations in a single hour, compute
    # aggregations per (location, metric), and batch-upsert all results.
    def aggregate_hour_batch(location_ids, hour_start)
      hour_end = hour_start + 1.hour

      # Single query: all readings for all locations in this hour
      # Aggregate directly in SQL — no need to load individual rows into Ruby
      raw_groups = WeatherStationApiRawValue
        .where(weather_station_api_location_id: location_ids)
        .where(sample_time: hour_start...hour_end)
        .group(:weather_station_api_location_id, :weather_station_api_metric_id)
        .pluck(
          :weather_station_api_location_id,
          :weather_station_api_metric_id,
          Arel.sql("AVG(scaled_value)"),
          Arel.sql("SUM(scaled_value)"),
          Arel.sql("COUNT(*)")
        )
      if raw_groups.empty?
        return 0
      end

      now = Time.current
      rows = raw_groups.map do |loc_id, metric_id, avg_val, sum_val, count|
        {
          weather_station_api_location_id: loc_id,
          weather_station_api_metric_id: metric_id,
          date: hour_start.to_date,
          hour: hour_start.hour,
          avg_value: avg_val,
          sum_value: sum_val,
          sample_count: count,
          created_at: now,
          updated_at: now
        }
      end

      batch_upsert(rows)

      rows.size
    end

    # ── MySQL batch upsert ─────────────────────────────────────────────

    def batch_upsert(rows)
      if rows.empty?
        return
      end

      columns = rows.first.keys
      col_names = columns.map { |c| "`#{c}`" }.join(", ")

      # Build value tuples with proper sanitization
      value_sets = rows.map do |row|
        values = row.values
        placeholders = values.map { "?" }
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
