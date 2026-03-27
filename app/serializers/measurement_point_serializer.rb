class MeasurementPointSerializer < Blueprinter::Base
  identifier :id

  view :default do
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
  end

  view :live_fields do
    field :last_value do |mp|
      mp.live_display_value[:value]
    end

    field :effective_unit do |mp|
      mp.live_display_value[:unit]
    end
  end

  view :live do
    include_view :default
    include_view :live_fields
  end

  view :live_poll do
    include_view :live_fields

    fields :alarm_state

    field :last_value_at do |mp|
      mp.last_decoded_value_at
    end
  end

  view :with_details do
    include_view :default

    field :plc_name do |mp|
      mp.plc&.name
    end

    field :interface_communication_type do |mp|
      mp.register_template.interface_register_mappings.first&.interface&.communication_type
    end

    field :interface_io_number do |mp|
      mp.register_template.interface_register_mappings.first&.interface&.io_number
    end

    association :measurement_subtype, blueprint: MeasurementSubtypeSerializer
    association :register_template, blueprint: RegisterTemplateSerializer
  end

  view :with_details_live do
    include_view :with_details
    include_view :live_fields
  end
end
