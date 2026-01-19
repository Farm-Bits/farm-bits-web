class MeasurementPoint < ApplicationRecord
  audited

  belongs_to :measurement_subtype, optional: true
  belongs_to :register_template
  belongs_to :plc
  belongs_to :segment, optional: true
  belongs_to :site, optional: true

  validates :name, presence: true
  validates :register_template_id, uniqueness: { scope: :plc_id }
  validate :register_template_matches_plc_version
  validates :chart_type_override, inclusion: { in: MeasurementSubtype::CHART_TYPES }, allow_blank: true
  validates :color_override, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: 'must be a valid hex color' }, allow_blank: true
  validates :polling_interval_seconds,
    presence: true,
    numericality: { only_integer: true, greater_than: 0 },
    if: -> { data_collection_enabled }
  validate :measurement_subtype_present_if_active_interface
  validate :measurement_subtype_data_category_matches_register_template
  validate :measurement_subtype_data_category_is_present_on_interface_mapping

  before_save :deactivate_conflicting_measurement_points

  class WriteValidationError < StandardError;
  end

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

  def validate_write(value)
    if !register_template.group_name.present?
      return []
    end

    group_points = fetch_group_points
    simulated_states = build_simulated_states(group_points, value)

    RegisterGroupValidator.new(simulated_states).validate
  end

  def write_value!(value, skip_validation: false)
    if !skip_validation
      errors = validate_write(value)

      if errors.any?
        raise WriteValidationError, errors.join('; ')
      end
    end

    data = register_template.encode_value(value)

    # TODO: Implement actual write to PLC
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

    def measurement_subtype_present_if_active_interface
      if !active || measurement_subtype.present? || !register_template.present?
        return
      end

      is_interface_measurement = register_template.interface_register_mappings
        .where(category: MeasurementSubtype::DATA_CATEGORIES)
        .any?
      if is_interface_measurement
        errors.add(:measurement_subtype, 'must be present for active interface measurements')
      end
    end

    def measurement_subtype_data_category_matches_register_template
      if !measurement_subtype.present? ||
        !register_template.present? ||
        !register_template.category.in?(MeasurementSubtype::DATA_CATEGORIES)
        return
      end

      if measurement_subtype.data_category != register_template.category
        errors.add(
          :measurement_subtype,
          "data_category '#{measurement_subtype.data_category}' does not match " \
          "register template category '#{register_template.category}'"
        )
      end
    end

    def measurement_subtype_data_category_is_present_on_interface_mapping
      if !measurement_subtype.present? ||
        !register_template.category.in?(MeasurementSubtype::DATA_CATEGORIES)
        return
      end

      interface_categories_configured = register_template.interface_register_mappings
        .where(category: MeasurementSubtype::DATA_CATEGORIES)
        .pluck(:category)

      category = measurement_subtype.data_category
      if interface_categories_configured.any? && !interface_categories_configured.include?(category)
        errors.add(
          :measurement_subtype,
          "requires a '#{category}' register mapping for one of the interfaces, " \
          "but none is configured"
        )
      end
    end

    def deactivate_conflicting_measurement_points
      if !active ||
        !register_template.present? ||
        !register_template.category.in?(MeasurementSubtype::DATA_CATEGORIES)
        return
      end

      interface_ids = register_template.interface_register_mappings
        .where(category: MeasurementSubtype::DATA_CATEGORIES)
        .pluck(:interface_id)
      if interface_ids.empty?
        return
      end

      plc.measurement_points
        .joins(register_template: :interface_register_mappings)
        .where(active: true)
        .where(interface_register_mappings: {
          interface_id: interface_ids,
          category: MeasurementSubtype::DATA_CATEGORIES
        })
        .where.not(id: id)
        .update_all(
          name: register_template.name,
          description: register_template.description,
          unit_override: nil,
          chart_type_override: nil,
          color_override: nil,
          data_collection_enabled: false,
          polling_interval_seconds: nil,
          factor_override: nil,
          offset_override: nil,
          alarm_low: nil,
          alarm_high: nil,
          warning_low: nil,
          warning_high: nil,
          active: false,
          measurement_subtype_id: nil
        )
    end

    def fetch_group_points
      if !register_template.group_name.present?
        return []
      end

      plc.measurement_points
        .joins(:register_template)
        .where(register_templates: {
          plc_version_id: register_template.plc_version_id,
          group_name: register_template.group_name
        })
        .to_a
    end

    def build_simulated_states(group_points, new_value)
      group_points.map do |point|
        if point.id == id
          SimulatedPoint.new(point, new_value)
        else
          point
        end
      end
    end

    SimulatedPoint = Struct.new(:measurement_point, :simulated_value) do
      def last_decoded_value
        simulated_value
      end

      def register_template
        measurement_point.register_template
      end

      def method_missing(method, *args, &block)
        measurement_point.send(method, *args, &block)
      end

      def respond_to_missing?(method, include_private = false)
        measurement_point.respond_to?(method, include_private)
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
