class AnalyticsQueryService
  def self.eligible_scope(site)
    MeasurementPoint
      .operational
      .user_visible
      .where(site_id: site.id)
      .where(data_collection_enabled: true)
  end

  def self.hourly(measurement_point_ids, start_date, end_date, time_zone)
    tz = ActiveSupport::TimeZone[time_zone]
    utc_start = tz.local(start_date.year, start_date.month, start_date.day).utc
    utc_end = tz.local(end_date.year, end_date.month, end_date.day, 23, 59, 59).utc

    aggregations = HourlyAggregation
      .where(measurement_point_id: measurement_point_ids)
      .where(hour_timestamp: utc_start..utc_end)
      .order(:hour_timestamp)

    grouped = aggregations.group_by(&:measurement_point_id)
    summary = grouped.transform_values { |records| build_summary(records) }

    { aggregations: grouped, summary: summary }
  end

  def self.raw(measurement_point_ids, start_time, end_time, time_zone)
    tz = ActiveSupport::TimeZone[time_zone]
    utc_start = tz.local(start_time.year, start_time.month, start_time.day, start_time.hour).utc
    utc_end = tz.local(end_time.year, end_time.month, end_time.day, end_time.hour, 59, 59).utc

    values = RawValue
      .where(measurement_point_id: measurement_point_ids)
      .where(sample_time: utc_start..utc_end)
      .order(:sample_time)

    grouped = values.group_by(&:measurement_point_id)

    { raw_values: grouped }
  end

  def self.build_summary(records)
    if records.empty?
      return {}
    end

    value_type = records.first.value_type
    base = {
      measurement_point_id: records.first.measurement_point_id,
      value_type: value_type,
      reading_count: records.sum(&:reading_count)
    }

    case value_type
    when 'instantaneous'
      base.merge(
        min_value: records.filter_map(&:min_value).min.to_f,
        max_value: records.filter_map(&:max_value).max.to_f,
        avg_value: compute_weighted_avg(records)
      )
    when 'accumulative'
      sorted = records.sort_by(&:hour_timestamp)
      base.merge(
        start_value: sorted.first.start_value.to_f,
        end_value: sorted.last.end_value.to_f,
        total_delta: records.filter_map(&:delta).sum.to_f
      )
    when 'status'
      total_on = records.filter_map(&:time_on_seconds).sum
      total_off = records.filter_map(&:time_off_seconds).sum
      total_time = total_on + total_off
      base.merge(
        total_time_on_seconds: total_on,
        total_time_off_seconds: total_off,
        on_percentage: total_time > 0 ? (total_on.to_f / total_time * 100).round(1) : nil,
        total_transitions: records.filter_map(&:transition_count).sum
      )
    else
      base
    end
  end

  def self.compute_weighted_avg(records)
    valid = records.select { |r| r.avg_value.present? && r.reading_count > 0 }
    if valid.empty?
      return nil
    end

    total_readings = valid.sum(&:reading_count)
    weighted_sum = valid.sum { |r| r.avg_value.to_f * r.reading_count }
    (weighted_sum / total_readings).round(4)
  end

  private_class_method :build_summary, :compute_weighted_avg
end
