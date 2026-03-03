class WeatherHourlyAggregationSerializer < Blueprinter::Base
  identifier :id

  fields :sample_count

  field :hour_timestamp do |ha|
    ha.hour_timestamp.utc.iso8601
  end

  field :min_value do |ha|
    ha.min_value&.to_f
  end

  field :max_value do |ha|
    ha.max_value&.to_f
  end

  field :avg_value do |ha|
    ha.avg_value&.to_f
  end

  field :sum_value do |ha|
    ha.sum_value&.to_f
  end
end
