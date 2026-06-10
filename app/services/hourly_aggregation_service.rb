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
      scope = MeasurementPoint
        .operational
        .where(data_collection_enabled: true)
        .includes(:measurement_subtype)

      if @measurement_point_ids
        scope = scope.where(id: @measurement_point_ids)
      end

      scope
    end

    # ── Phase 1: Detect start times ───────────────────────────────────────

    def detect_start_times(mp_ids)
      latest_aggs = HourlyAggregation
        .where(measurement_point_id: mp_ids)
        .group(:measurement_point_id)
        .maximum(:hour_timestamp)

      start_times = {}
      mp_ids_without_aggs = []
      mp_ids.each do |mp_id|
        if latest_aggs[mp_id]
          start_times[mp_id] = latest_aggs[mp_id].utc
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
          start_times[mp_id] = sample_time.utc.beginning_of_hour
        end
      end

      start_times
    end

    # ── Phase 2: Process a batch ──────────────────────────────────────────

    def process_batch(mps)
      processed = 0
      errors = []

      mp_map = mps.index_by(&:id)
      mp_ids = mps.map(&:id)

      start_times = detect_start_times(mp_ids)
      if start_times.empty?
        return { processed: 0, errors: [] }
      end

      mps_by_start = start_times
        .group_by { |_, time| time }
        .transform_values { |pairs| pairs.map(&:first) }

      mps_by_start.each do |since_time, group_mp_ids|
        begin
          count = aggregate_since(group_mp_ids, mp_map, since_time)
          processed += count
        rescue => e
          group_mp_ids.each do |mp_id|
            errors << { measurement_point_id: mp_id, error: e.message }
          end
          Rails.logger.error(
            "[HourlyAggregation] Batch failed since #{since_time} " \
            "for #{group_mp_ids.size} measurement points: #{e.message}"
          )
        end
      end

      { processed: processed, errors: errors }
    end

    # ── Phase 3: Aggregate since a start time ─────────────────────────────

    def aggregate_since(mp_ids, mp_map, since_time)
      end_time = @current_hour + 1.hour

      raw_rows = RawValue
        .where(measurement_point_id: mp_ids)
        .where(sample_time: since_time...end_time)
        .order(:measurement_point_id, :sample_time)
        .pluck(:measurement_point_id, :scaled_value, :sample_time)
      if raw_rows.empty?
        return 0
      end

      # Group by (mp_id, hour)
      readings_by_mp_hour = {}
      raw_rows.each do |mp_id, scaled_value, sample_time|
        hour = sample_time.utc.beginning_of_hour
        key = [mp_id, hour]
        (readings_by_mp_hour[key] ||= []) << [scaled_value, sample_time]
      end

      # Identify status MPs that actually have readings this run, and fetch
      # their prior states for the earliest hour we are about to write.
      mp_ids_with_readings = readings_by_mp_hour.keys.map { |mp_id, _hour| mp_id }.uniq
      status_mp_ids = mp_ids_with_readings.select do |mp_id|
        mp_map[mp_id]&.measurement_subtype&.value_type == "status"
      end

      prior_states = fetch_prior_states(status_mp_ids, since_time)

      # Process hours in chronological order, carrying forward status state
      sorted_keys = readings_by_mp_hour.keys.sort_by { |mp_id, hour| [hour, mp_id] }

      rows = []
      sorted_keys.each do |mp_id, hour|
        mp = mp_map[mp_id]
        if !mp
          next
        end

        readings = readings_by_mp_hour[[mp_id, hour]]
        value_type = mp.measurement_subtype.value_type
        hour_end = hour + 1.hour

        attrs = base_attributes(mp, hour, value_type, readings)
        ALL_AGG_KEYS.each { |k| attrs[k] = nil }

        case value_type
        when "accumulative"
          attrs.merge!(accumulative_attributes(readings))
        when "instantaneous"
          attrs.merge!(instantaneous_attributes(readings))
        when "status"
          prior_state = prior_states[mp_id]
          attrs.merge!(status_attributes(readings, hour, hour_end, prior_state))
          # Carry forward: last value of this hour becomes prior state for next hour
          prior_states[mp_id] = readings.last[0].to_i
        end

        rows << attrs
      end

      rows.each_slice(500) do |chunk|
        batch_upsert(chunk)
      end

      rows.size
    end

    # ── Prior state lookup (one query for all status MPs) ─────────────────

    def fetch_prior_states(status_mp_ids, since_time)
      prior_states = {}

      if status_mp_ids.empty?
        return prior_states
      end

      status_mp_ids.each do |mp_id|
        value = RawValue
          .where(measurement_point_id: mp_id)
          .where(sample_time: ...since_time)
          .order(sample_time: :desc)
          .limit(1)
          .pick(:scaled_value)

        if value.nil?
          next
        end

        prior_states[mp_id] = value.to_i
      end

      prior_states
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
