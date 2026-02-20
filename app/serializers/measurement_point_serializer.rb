class MeasurementPointSerializer < Blueprinter::Base
  identifier :id

  fields :name,
    :description,
    :unit_override,
    :effective_unit,
    :chart_type_override,
    :effective_chart_type,
    :color_override,
    :effective_color,
    :data_collection_enabled,
    :polling_interval_seconds,
    :alarm_state,
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

  field :last_value do |mp|
    mp.scaled_last_decoded_value
  end

  field :last_value_at do |mp|
    mp.last_decoded_value_at
  end

  view :with_details do
    field :plc_name do |mp|
      mp.plc&.name
    end

    field :register_name do |mp|
      mp.register_template&.name
    end

    field :value_format do |mp|
      mp.register_template&.value_format
    end

    field :enum_values do |mp|
      mp.register_template&.enum_values
    end

    association :measurement_subtype, blueprint: MeasurementSubtypeSerializer
    association :segment, blueprint: SegmentSerializer
  end
end
