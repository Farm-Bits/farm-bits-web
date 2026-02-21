class MeasurementPoint < ApplicationRecord
  audited

  belongs_to :measurement_subtype, optional: true
  belongs_to :register_template
  belongs_to :plc
  belongs_to :segment, optional: true
  belongs_to :site, optional: true

  has_many :raw_values, dependent: :delete_all

  has_many :hourly_aggregations, dependent: :delete_all

  validates :name, presence: true
  validates :register_template_id, uniqueness: { scope: :plc_id }
  validate :register_template_matches_plc_version
  validates :chart_type_override, inclusion: { in: MeasurementSubtype::CHART_TYPES }, allow_blank: true
  validate :chart_type_override_compatible_with_value_type
  validates :color_override, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: 'must be a valid hex color' }, allow_blank: true
  validates :polling_interval_seconds,
    presence: true,
    numericality: { only_integer: true, greater_than: 0 },
    if: -> { data_collection_enabled }
  validate :measurement_subtype_present_if_active_interface
  validate :measurement_subtype_data_category_matches_register_template

  before_save :deactivate_conflicting_measurement_points
  before_save :sync_data_collection_with_active_if_needed
  after_update :sync_to_plc_registers

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

  def reverse_scaled(value)
    if !register_template.numeric_register?
      return value
    end

    ((value.to_f - effective_offset) / effective_factor)
  end

  def validate_write(value)
    if !register_template.group_name.present?
      return []
    end

    group_points = fetch_group_points
    simulated_states = build_simulated_states(group_points, value)

    RegisterGroupValidator.new(simulated_states).validate
  end

  def update_last_decoded_value!(decoded_value, timestamp = Time.current)
    update_columns(
      last_decoded_value: serialize_for_storage(decoded_value),
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

  def configuration_measurement_points
    interface_ids = register_template.interface_register_mappings.pluck(:interface_id)
    if interface_ids.empty?
      return MeasurementPoint.none
    end

    MeasurementPoint
      .joins(register_template: :interface_register_mappings)
      .where(plc_id: plc_id)
      .where(register_templates: { category: ['interface_configuration', 'operation_mode_configuration'] })
      .where(interface_register_mappings: { interface_id: interface_ids })
      .includes(:register_template)
      .distinct
  end

  def syncable_measurement_points
    interface_ids = register_template.interface_register_mappings.pluck(:interface_id)
    if interface_ids.empty?
      return MeasurementPoint.none
    end

    MeasurementPoint
      .joins(register_template: :interface_register_mappings)
      .where(plc_id: plc_id)
      .where(register_template: { category: 'measurement_point_configuration' })
      .where(interface_register_mappings: { interface_id: interface_ids })
      .where.not(register_template: { sync_field: [nil, ''] })
      .includes(:register_template)
      .distinct
  end

  def value_type
    measurement_subtype&.value_type
  end

  def needs_polling?
    if !active? || !data_collection_enabled?
      return false
    end

    if polling_interval_seconds.nil?
      return true
    end

    if last_decoded_value_at.nil?
      return true
    end

    Time.current - last_decoded_value_at >= polling_interval_seconds
  end

  def serialize_for_storage(decoded_value)
    case register_template.value_format
    when 'boolean'
      decoded_value ? '1' : '0'
    else
      decoded_value.to_s
    end
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

    def chart_type_override_compatible_with_value_type
      if chart_type_override.blank? || measurement_subtype.blank?
        return
      end

      allowed = measurement_subtype.allowed_chart_types
      if allowed.include?(chart_type_override)
        return
      end

      errors.add(
        :chart_type_override,
        "#{chart_type_override} is not compatible with #{measurement_subtype.value_type} measurement type. " \
        "Allowed: #{allowed.join(', ')}"
      )
    end

    def measurement_subtype_present_if_active_interface
      if !active || measurement_subtype.present? || !register_template.present?
        return
      end

      if !register_template.category.in?(MeasurementSubtype::DATA_CATEGORIES)
        return
      end

      has_interface_mapping = register_template.interface_register_mappings.any?
      if has_interface_mapping
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

    def deactivate_conflicting_measurement_points
      if !active ||
        !register_template.present? ||
        !register_template.category.in?(MeasurementSubtype::DATA_CATEGORIES)
        return
      end

      interface_ids = register_template.interface_register_mappings.pluck(:interface_id)
      if interface_ids.empty?
        return
      end

      plc.measurement_points
        .joins(register_template: :interface_register_mappings)
        .where(active: true)
        .where(register_templates: { category: MeasurementSubtype::DATA_CATEGORIES })
        .where(interface_register_mappings: { interface_id: interface_ids })
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

    def sync_data_collection_with_active_if_needed
      if !will_save_change_to_active?
        return
      end

      old_active, new_active = active_change_to_be_saved
      if !new_active
        self.data_collection_enabled = false
        self.polling_interval_seconds = nil
        return
      end

      if !register_template.present? ||
        !register_template.category.in?(MeasurementSubtype::DATA_CATEGORIES)
        return
      end

      self.data_collection_enabled = true
      self.polling_interval_seconds ||= 270
    end

    def sync_to_plc_registers
      if !plc.gateway_id
        return
      end

      writes = []

      saved_changes.each_key do |field|
        sync_points = configuration_measurement_points
          .joins(:register_template)
          .where(register_templates: { sync_field: field })

        sync_points.each do |sync_point|
          writes << {
            measurement_point: sync_point,
            value: transform_value_for_plc(field)
          }
        end
      end

      if writes.empty?
        return
      end

      service = PlcWriteService.new(self)
      service.bulk_write!(writes)
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
end
