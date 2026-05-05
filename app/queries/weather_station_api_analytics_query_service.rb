class WeatherStationApiAnalyticsQueryService
  def self.hourly(weather_station_api_location_id, start_date, end_date, time_zone)
    tz = ActiveSupport::TimeZone[time_zone]
    utc_start = tz.local(start_date.year, start_date.month, start_date.day).utc
    utc_end = tz.local(end_date.year, end_date.month, end_date.day, 23, 59, 59).utc

    aggregations = WeatherStationApiHourlyAggregation
      .where(weather_station_api_location_id: weather_station_api_location_id)
      .where(hour_timestamp: utc_start..utc_end)
      .order(:hour_timestamp)
      .includes(weather_station_api_metric: :measurement_subtype)

    grouped = aggregations.group_by(&:weather_station_api_metric_id)

    summary = grouped.transform_values { |records| build_summary(records) }

    { aggregations: grouped, summary: summary }
  end

  def self.raw(weather_station_api_location_id, start_time, end_time, time_zone)
    if end_time - start_time > 24.hours
      end_time = start_time + 24.hours
    end

    tz = ActiveSupport::TimeZone[time_zone]
    utc_start = tz.local(start_time.year, start_time.month, start_time.day, start_time.hour).utc
    utc_end = tz.local(end_time.year, end_time.month, end_time.day, end_time.hour, 59, 59).utc

    raw_values = WeatherStationApiRawValue
      .where(weather_station_api_location_id: weather_station_api_location_id)
      .where(sample_time: utc_start..utc_end)
      .order(:sample_time)

    grouped = raw_values.group_by(&:weather_station_api_metric_id)

    { raw_values: grouped }
  end

  def self.latest(weather_station_api_location_id)
    latest_times = WeatherStationApiRawValue
      .where(weather_station_api_location_id: weather_station_api_location_id)
      .group(:weather_station_api_metric_id)
      .select(:weather_station_api_metric_id, "MAX(sample_time) AS max_sample_time")

    WeatherStationApiRawValue
      .joins("INNER JOIN (#{latest_times.to_sql}) AS lt ON weather_station_api_raw_values.weather_station_api_metric_id = lt.weather_station_api_metric_id AND weather_station_api_raw_values.sample_time = lt.max_sample_time")
      .where(weather_station_api_location_id: weather_station_api_location_id)
      .includes(:weather_station_api_metric)
  end

  def self.build_summary(records)
    if records.empty?
      return {}
    end

    value_type = records.first.weather_station_api_metric.measurement_subtype.value_type
    base = {
      weather_station_api_metric_id: records.first.weather_station_api_metric_id,
      value_type: value_type,
      sample_count: records.sum(&:sample_count)
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
        sum_value: sorted.last.sum_value.to_f - sorted.first.sum_value.to_f
      )
    else
      base
    end
  end

  def self.compute_weighted_avg(records)
    valid = records.select { |r| r.avg_value.present? && r.sample_count > 0 }
    if valid.empty?
      return nil
    end

    total_readings = valid.sum(&:sample_count)
    weighted_sum = valid.sum { |r| r.avg_value.to_f * r.sample_count }
    (weighted_sum / total_readings).round(4)
  end

  private_class_method :build_summary, :compute_weighted_avg
end
