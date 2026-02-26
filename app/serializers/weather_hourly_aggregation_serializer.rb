class WeatherHourlyAggregationSerializer < Blueprinter::Base
  identifier :id

  fields :date, :hour, :sample_count

  field :value do |ha|
    case ha.weather_station_api_metric&.aggregation
    when 'sum'
      ha.sum_value&.to_f
    when 'min'
      ha.min_value&.to_f
    when 'max'
      ha.max_value&.to_f
    else
      ha.avg_value&.to_f
    end
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
