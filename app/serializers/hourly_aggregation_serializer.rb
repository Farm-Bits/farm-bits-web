class HourlyAggregationSerializer < Blueprinter::Base
  identifier :id

  fields :date,
    :hour,
    :value_type,
    :reading_count,
    :time_on_seconds,
    :time_off_seconds,
    :transition_count,
    :first_reading_at,
    :last_reading_at,
    :measurement_point_id

  field :start_value do |ha|
    ha.start_value&.to_f
  end

  field :end_value do |ha|
    ha.end_value&.to_f
  end

  field :delta do |ha|
    ha.delta&.to_f
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
