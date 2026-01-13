class MeasurementPointSerializer < Blueprinter::Base
  identifier :id

  fields :name,
    :description,
    :unit_override,
    :chart_type_override,
    :color_override,
    :data_collection_enabled,
    :polling_interval_seconds,
    :factor_override,
    :offset_override,
    :alarm_low,
    :alarm_high,
    :warning_low,
    :warning_high,
    :position,
    :active,
    :measurement_subtype_id,
    :register_template_id,
    :segment_id

  field :effective_unit do |mp|
    mp.effective_unit
  end

  field :effective_chart_type do |mp|
    mp.effective_chart_type
  end

  field :effective_color do |mp|
    mp.effective_color
  end

  field :last_value do |mp|
    mp.scaled_last_decoded_value
  end

  field :last_value_at do |mp|
    mp.last_decoded_value_at
  end
end
