class AlertRuleSerializer < Blueprinter::Base
  identifier :id

  view :default do
    fields :name,
      :severity,
      :condition_type,
      :direction,
      :inactivity_seconds,
      :min_duration_seconds,
      :active,
      :measurement_point_id

    field :threshold_value do |rule|
      rule.threshold_value&.to_f
    end
  end

  view :with_measurement_point do
    include_view :default

    field :measurement_point_name do |rule|
      rule.measurement_point&.name
    end

    field :segment_name do |rule|
      rule.measurement_point&.segment&.name
    end

    field :unit do |rule|
      rule.measurement_point&.effective_unit
    end

    field :value_format do |rule|
      rule.measurement_point&.register_template&.value_format
    end
  end
end
