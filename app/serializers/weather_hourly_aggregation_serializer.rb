class WeatherHourlyAggregationSerializer < Blueprinter::Base
  identifier :id

  fields :date, :hour, :sample_count

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
