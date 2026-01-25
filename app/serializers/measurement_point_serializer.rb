class MeasurementPointSerializer < Blueprinter::Base
  identifier :id

  fields :name,
    :description,
    :unit_override,
    :chart_type_override,
    :color_override,
    :data_collection_enabled,
    :polling_interval_seconds,
    :position,
    :active,
    :measurement_subtype_id,
    :register_template_id,
    :segment_id

  field :factor_override do |mp|
    mp.factor_override&.to_f
  end

  field :offset_override do |mp|
    mp.offset_override&.to_f
  end

  field :alarm_low do |mp|
    mp.alarm_low&.to_f
  end

  field :alarm_high do |mp|
    mp.alarm_high&.to_f
  end

  field :warning_low do |mp|
    mp.warning_low&.to_f
  end

  field :warning_high do |mp|
    mp.warning_high&.to_f
  end

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
