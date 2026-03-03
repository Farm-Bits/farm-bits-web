class HourlyAggregationService
  MP_BATCH_SIZE = 100

  ALL_AGG_KEYS = %i[
    start_value end_value delta
    min_value max_value avg_value sum_value
    time_on_seconds time_off_seconds transition_count
  ].freeze

  def self.call(**args)
    new(**args).call
  end

  def initialize(measurement_point_ids: nil, now: Time.current)
    @measurement_point_ids = measurement_point_ids
    @current_hour = now.utc.beginning_of_hour
  end

  def call
    processed = 0
    errors = []

    eligible_measurement_points.find_in_batches(batch_size: MP_BATCH_SIZE) do |batch|
      result = process_batch(batch)
      processed += result[:processed]
      errors.concat(result[:errors])
    end

    { processed: processed, errors: errors }
  end

  private
    def eligible_measurement_points
      scope = MeasurementPoint.joins(plc: { gateway: { site: :company } })
        .where(active: true, data_collection_enabled: true)
        .where(plcs: { active: true })
        .where(gateways: { active: true })
        .where(sites: { companies: { active: true } })
        .where.not(measurement_subtype_id: nil)
        .includes(:measurement_subtype)

      if @measurement_point_ids
        scope = scope.where(id: @measurement_point_ids)
      end

      scope
    end

    # ── Phase 1: Batch gap detection ──────────────────────────────────────

    def detect_start_hours(mp_ids)
      latest_aggs = HourlyAggregation
        .where(measurement_point_id: mp_ids)
        .group(:measurement_point_id)
        .maximum(:hour_timestamp)
      # => { mp_id => 2026-02-17 14:00:00 UTC, ... }

      start_hours = {}
      mp_ids_without_aggs = []

      mp_ids.each do |mp_id|
        if latest_aggs[mp_id]
          start_hours[mp_id] = latest_aggs[mp_id].utc
        else
          mp_ids_without_aggs << mp_id
        end
      end

      if mp_ids_without_aggs.any?
        earliest_samples = RawValue
          .where(measurement_point_id: mp_ids_without_aggs)
          .group(:measurement_point_id)
          .minimum(:sample_time)

        earliest_samples.each do |mp_id, sample_time|
          start_hours[mp_id] = sample_time.utc.beginning_of_hour
        end
      end

      start_hours
    end

    def build_hour_plan(mp_ids)
      start_hours = detect_start_hours(mp_ids)
      if start_hours.empty?
        return {}
      end

      plan = {}
      start_hours.each do |mp_id, start_hour|
        hours = []
        h = start_hour
        while h <= @current_hour
          hours << h
          h += 1.hour
        end

        if hours.any?
          plan[mp_id] = hours
        end
      end

      plan
    end

    # ── Phase 2: Process a batch ──────────────────────────────────────────

    def process_batch(mps)
      processed = 0
      errors = []

      mp_map = mps.index_by(&:id)
      mp_ids = mps.map(&:id)

      plan = build_hour_plan(mp_ids)
      if plan.empty?
        return { processed: 0, errors: [] }
      end

      all_hours = plan.values.flatten.uniq.sort
      all_hours.each do |hour_start|
        mp_ids_for_hour = plan.filter_map { |mp_id, hours| mp_id if hours.include?(hour_start) }
        if mp_ids_for_hour.empty?
          next
        end

        begin
          count = aggregate_hour_batch(mp_ids_for_hour, mp_map, hour_start)
          processed += count
        rescue => e
          mp_ids_for_hour.each do |mp_id|
            errors << { measurement_point_id: mp_id, error: e.message }
          end
          Rails.logger.error(
            "[HourlyAggregation] Batch failed for hour #{hour_start}: #{e.message}"
          )
        end
      end

      { processed: processed, errors: errors }
    end

    # ── Phase 3: Batch aggregate + upsert ─────────────────────────────────

    def aggregate_hour_batch(mp_ids, mp_map, hour_start)
      hour_end = hour_start + 1.hour

      raw_rows = RawValue
        .where(measurement_point_id: mp_ids)
        .where(sample_time: hour_start...hour_end)
        .order(:measurement_point_id, :sample_time)
        .pluck(:measurement_point_id, :scaled_value, :sample_time)
      if raw_rows.empty?
        return 0
      end

      readings_by_mp = {}
      raw_rows.each do |mp_id, scaled_value, sample_time|
        (readings_by_mp[mp_id] ||= []) << [scaled_value, sample_time]
      end

      status_mp_ids = readings_by_mp.keys.select do |mp_id|
        mp_map[mp_id]&.measurement_subtype&.value_type == "status"
      end

      prior_states = {}
      if status_mp_ids.any?
        prior_rows = RawValue
          .where(measurement_point_id: status_mp_ids)
          .where(sample_time: ...hour_start)
          .where(
            "sample_time = (SELECT MAX(r2.sample_time) FROM raw_values r2 " \
            "WHERE r2.measurement_point_id = raw_values.measurement_point_id " \
            "AND r2.sample_time < ?)", hour_start
          )
          .pluck(:measurement_point_id, :scaled_value)

        prior_rows.each do |mp_id, val|
          prior_states[mp_id] = val.to_i
        end
      end

      rows = []
      readings_by_mp.each do |mp_id, readings|
        mp = mp_map[mp_id]
        if !mp
          next
        end

        value_type = mp.measurement_subtype.value_type
        attrs = base_attributes(mp, hour_start, value_type, readings)

        ALL_AGG_KEYS.each { |k| attrs[k] = nil }

        case value_type
        when "accumulative"
          attrs.merge!(accumulative_attributes(readings))
        when "instantaneous"
          attrs.merge!(instantaneous_attributes(readings))
        when "status"
          prior_state = prior_states[mp_id]
          attrs.merge!(status_attributes(readings, hour_start, hour_end, prior_state))
        end

        rows << attrs
      end

      batch_upsert(rows) if rows.any?

      rows.size
    end

    # ── Aggregation logic ─────────────────────────────────────────────────

    def base_attributes(mp, hour_start, value_type, readings)
      {
        measurement_point_id: mp.id,
        hour_timestamp: hour_start,
        value_type: value_type,
        reading_count: readings.size,
        first_reading_at: readings.first[1],
        last_reading_at: readings.last[1]
      }
    end

    def accumulative_attributes(readings)
      values = readings.map(&:first)
      start_val = values.first
      end_val = values.last

      {
        start_value: start_val,
        end_value: end_val,
        delta: end_val - start_val
      }
    end

    def instantaneous_attributes(readings)
      values = readings.map(&:first)

      {
        min_value: values.min,
        max_value: values.max,
        avg_value: values.sum / values.size.to_f,
        sum_value: values.sum
      }
    end

    def status_attributes(readings, hour_start, hour_end, prior_state)
      time_on = 0.0
      time_off = 0.0
      transitions = 0

      first_value, first_time = readings.first
      gap_before = first_time - hour_start
      if gap_before > 0
        state_before = prior_state.nil? ? first_value.to_i : prior_state

        if state_before == 1
          time_on += gap_before
        else
          time_off += gap_before
        end

        if !prior_state.nil? && prior_state != first_value.to_i
          transitions += 1
        end
      end

      readings.each_cons(2) do |(val_a, time_a), (val_b, time_b)|
        duration = time_b - time_a

        if val_a.to_i == 1
          time_on += duration
        else
          time_off += duration
        end

        transitions += 1 if val_a.to_i != val_b.to_i
      end

      last_value, last_time = readings.last
      gap_after = hour_end - last_time
      if gap_after > 0
        if last_value.to_i == 1
          time_on += gap_after
        else
          time_off += gap_after
        end
      end

      {
        time_on_seconds: time_on.round(1),
        time_off_seconds: time_off.round(1),
        transition_count: transitions
      }
    end

    # ── MySQL batch upsert ────────────────────────────────────────────────

    def batch_upsert(rows)
      if rows.empty?
        return
      end

      now = Time.current
      columns = rows.first.keys + %i[created_at updated_at]
      col_names = columns.map { |c| "`#{c}`" }.join(", ")

      value_sets = rows.map do |row|
        values = row.values + [now, now]
        placeholders = values.map { "?" }
        "(#{placeholders.join(', ')})"
      end

      all_values = rows.flat_map { |row| row.values + [now, now] }

      update_cols = columns - %i[measurement_point_id hour_timestamp created_at]
      update_clause = update_cols.map { |c| "`#{c}` = VALUES(`#{c}`)" }.join(", ")

      sql = <<~SQL
        INSERT INTO `hourly_aggregations` (#{col_names})
        VALUES #{value_sets.join(', ')}
        ON DUPLICATE KEY UPDATE #{update_clause}
      SQL

      sanitized = ActiveRecord::Base.sanitize_sql_array([sql, *all_values])
      ActiveRecord::Base.connection.execute(sanitized)
    end
end
