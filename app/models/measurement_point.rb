class MeasurementPoint < ApplicationRecord
  audited

  belongs_to :measurement_subtype, optional: true
  belongs_to :plc
  belongs_to :register_template
  belongs_to :client

  validates :name, presence: true
  validates :register_template_id, uniqueness: { scope: :plc_id }
  validate :register_template_matches_plc_version
  validates :chart_type_override, inclusion: { in: MeasurementSubtype::CHART_TYPES }, allow_blank: true
  validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: 'must be a valid hex color' }, allow_blank: true
  validates :polling_interval_seconds, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :measurement_subtype_required_for_sensor_and_control, if: :active?
  validate :measurement_subtype_category_matches_interface

  def effective_unit
    unit_override.presence || measurement_subtype&.default_unit
  end

  def effective_chart_type
    chart_type_override.presence || measurement_subtype&.default_chart_type
  end

  def effective_color
    color_override.presence || measurement_subtype&.default_color
  end

  def effective_factor
    factor_override.presence || register_template.factor
  end

  def effective_offset
    offset_override.presence || register_template.offset
  end

  def data_collection_enabled?
    data_collection_enabled_override.nil? ? register_template.default_data_collection_enabled : data_collection_enabled_override
  end

  def effective_polling_interval_seconds
    polling_interval_seconds_override.presence || register_template.default_polling_interval_seconds
  end

  def scale_decoded_value(decoded_value)
    if decoded_value.nil?
      return nil
    end

    if register_template.numeric_register?
      (decoded_value.to_f * effective_factor) + effective_offset
    else
      decoded_value
    end
  end

  def scaled_last_decoded_value
    scale_decoded_value(last_decoded_value)
  end

  def write_value!(value)
    data = register_template.encode_value(value)

    # plc.modbus_client.write_registers(
    #   register_template.address,
    #   data
    # )

    update_columns(
      last_decoded_value: serialize_for_storage(value),
      last_decoded_value_at: Time.current,
      updated_at: Time.current
    )
  end

  def update_last_decoded_value!(data, timestamp = Time.current)
    decoded = register_template.decode_data(data)

    update_columns(
      last_decoded_value: serialize_for_storage(decoded),
      last_decoded_value_at: timestamp,
      updated_at: Time.current
    )
  end

  def alarm_state
    if scaled_last_decoded_value.nil? || !register_template.numeric_register?
      return :none
    end

    if alarm_low.present? && scaled_last_decoded_value < alarm_low
      return :alarm_low
    end

    if alarm_high.present? && scaled_last_decoded_value > alarm_high
      return :alarm_high
    end

    if warning_low.present? && scaled_last_decoded_value < warning_low
      return :warning_low
    end

    if warning_high.present? && scaled_last_decoded_value > warning_high
      return :warning_high
    end

    :normal
  end

  private
    def register_template_matches_plc_version
      if !plc.present? || !register_template.present?
        return
      end

      if register_template.plc_version_id != plc.plc_version_id
        errors.add(:register_template, "must belong to the PLC's version")
      end
    end

    def measurement_subtype_required_for_sensor_and_control
      if register_template.category.in?(%w[sensor control]) && measurement_subtype.nil?
        errors.add(:measurement_subtype, "is required for #{register_template.category} registers")
      end
    end

    def measurement_subtype_category_matches_interface
      if !register_template.interface.present? || !measurement_subtype.present?
        return
      end

      if register_template.interface.input? && measurement_subtype.control?
        errors.add(:measurement_subtype, "cannot be a control type on input interface")
      elsif register_template.interface.output? && measurement_subtype.sensor?
        errors.add(:measurement_subtype, "cannot be a sensor type on output interface")
      end
    end

    def serialize_for_storage(decoded_value)
      case register_template.value_format
      when 'ascii_string'
        decoded_value.to_s
      when 'boolean'
        decoded_value ? '1' : '0'
      else
        decoded_value.to_s
      end
    end
end
