class AlertSerializer < Blueprinter::Base
  identifier :id

  view :default do
    fields :rule_name,
      :severity,
      :condition_type,
      :direction,
      :inactivity_seconds,
      :min_duration_seconds,
      :measurement_point_name,
      :segment_name,
      :unit,
      :started_value,
      :ended_value,
      :measurement_point_id,
      :alert_rule_id,
      :site_id,
      :started_at,
      :ended_at

    field :threshold_value do |alert|
      alert.threshold_value&.to_f
    end

    field :open do |alert|
      alert.open?
    end

    field :duration_seconds do |alert|
      alert.duration_seconds
    end
  end
end
