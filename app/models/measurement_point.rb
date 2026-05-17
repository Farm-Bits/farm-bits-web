class MeasurementPoint < ApplicationRecord
  audited

  belongs_to :measurement_subtype, optional: true
  belongs_to :register_template
  belongs_to :plc, optional: true
  belongs_to :modbus_device, optional: true
  belongs_to :segment, optional: true
  belongs_to :site, optional: true

  has_many :raw_values, dependent: :delete_all

  has_many :hourly_aggregations, dependent: :delete_all

  validates :name, presence: true
  validates :register_template_id, uniqueness: { scope: [:plc_id, :modbus_device_id] }
  validate :register_template_matches_modbus_firmware_version
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
  after_update :sync_read_after_enable
  after_update :trigger_behavior_sync

  READ_COORDINATES_INCLUDES = [
    :register_template,
    { plc: [:gateway, :modbus_firmware_version] },
    {
      modbus_device: [
        :gateway,
        { modbus_firmware_version: {} },
        { plc: [:gateway, { modbus_firmware_version: :relay_mappings }] }
      ]
    }
  ].freeze

  WRITE_COORDINATES_INCLUDES = [
    :register_template,
    { plc: [:gateway] },
    {
      modbus_device: [
        :gateway,
        { plc: [:gateway, { modbus_firmware_version: :relay_mappings }] }
      ]
    }
  ].freeze

  scope :user_visible, -> {
    joins(:register_template).where(register_templates: { user_visibility: 'visible' })
  }
  # Topology-agnostic operational scope. An MP is operational when:
  #   - It's active and has a measurement subtype assigned
  #   - Its site's company is active
  #   - Its read endpoint is reachable, where "reachable" means:
  #       PLC-native:                   plc.active AND plc.gateway.active
  #       Gateway-direct ModbusDevice:  modbus_device.gateway.active
  #       PLC-relayed ModbusDevice:     modbus_device.plc.active AND modbus_device.plc.gateway.active
  #
  # Use this as the base for any service-level scope that wants
  # "MPs we should currently care about" (analytics listing, hourly
  # aggregation, etc.). The polling job has its own simpler filter
  # because it relies on read_coordinates returning nil for
  # non-reachable MPs.
  scope :operational, -> {
    joins(:site)
      .joins('INNER JOIN companies ON companies.id = sites.company_id')
      .where(active: true)
      .where.not(measurement_subtype_id: nil)
      .where(companies: { active: true })
      .where(<<~SQL.squish)
        (
          measurement_points.plc_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM plcs
            INNER JOIN gateways ON gateways.id = plcs.gateway_id
            WHERE plcs.id = measurement_points.plc_id
              AND plcs.active = TRUE
              AND gateways.active = TRUE
          )
        ) OR (
          measurement_points.modbus_device_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM modbus_devices
            LEFT JOIN gateways AS md_direct_gw ON md_direct_gw.id = modbus_devices.gateway_id
            LEFT JOIN plcs     AS md_host_plc  ON md_host_plc.id  = modbus_devices.plc_id
            LEFT JOIN gateways AS md_host_gw   ON md_host_gw.id   = md_host_plc.gateway_id
            WHERE modbus_devices.id = measurement_points.modbus_device_id
              AND (
                (modbus_devices.gateway_id IS NOT NULL AND md_direct_gw.active = TRUE)
                OR
                (modbus_devices.plc_id IS NOT NULL AND md_host_plc.active = TRUE AND md_host_gw.active = TRUE)
              )
          )
        )
      SQL
  }
  scope :due_for_polling, -> {
    where(<<~SQL.squish)
      last_decoded_value_at IS NULL
      OR last_decoded_value_at + INTERVAL polling_interval_seconds SECOND < NOW()
    SQL
  }

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

  def live_display_value
    @live_display_value ||= compute_live_display_value
  end

  def validate_write(value)
    if !register_template.group_name.present?
      return []
    end

    group_points = fetch_group_points
    simulated_states = build_simulated_states(group_points, value)

    Validators::RegisterGroupValidator.new(simulated_states).validate
  end

  def sibling_measurement_points
    interface_ids = register_template.interface_register_mappings.pluck(:interface_id)
    if interface_ids.empty?
      return MeasurementPoint.none
    end

    MeasurementPoint
      .joins(register_template: :interface_register_mappings)
      .where(plc_id: plc_id)
      .where(interface_register_mappings: { interface_id: interface_ids })
      .where.not(id: id)
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
      bool = ActiveModel::Type::Boolean.new.cast(decoded_value)
      bool ? '1' : '0'
    else
      decoded_value.to_s
    end
  end

  ModbusReadCoordinates = Struct.new(
    :gateway,
    :target_ip,
    :slave_id,
    :register_type,
    :address,
    :count,
    :bulk_strategy,
    :template_bulk_group,    # :template_bulk_read only
    :template_bulk_base,     # :template_bulk_read only (wire-ready)
    :template_bulk_offset,   # :template_bulk_read only
    :relay_slot_number,      # relay strategies only
    :relay_modbus_device_id, # relay strategies only
    keyword_init: true
  ) do
    # Stable key. Two coordinates with the same key share a Modbus session.
    def endpoint_key
      [gateway.id, target_ip, slave_id]
    end
  end

  def read_coordinates
    if modbus_device.present?
      if modbus_device.polled_by_gateway?
        return read_direct_coordinates
      end

      if modbus_device.polled_by_plc?
        return read_plc_relayed_coordinates
      end

      return nil
    end

    if plc.present?
      return read_direct_coordinates
    end

    nil
  end

  ModbusWriteCoordinates = Struct.new(
    :gateway,
    :target_ip,
    :slave_id,
    :register_type,
    :address,
    keyword_init: true
  ) do
    def endpoint_key
      [gateway.id, target_ip, slave_id]
    end
  end

  def write_coordinates
    if !register_template.present? || register_template.read_only?
      return nil
    end

    if modbus_device.present?
      if modbus_device.polled_by_gateway?
        return write_coordinates_direct(modbus_device)
      end

      if modbus_device.polled_by_plc?
        return write_coordinates_via_relay_write
      end

      return nil
    end

    if plc.present?
      return write_coordinates_direct(plc)
    end

    nil
  end

  def write_target
    if modbus_device.present?
      return modbus_device
    end

    if plc.present?
      return plc
    end

    nil
  end

  def relay_host_plc
    if !modbus_device.present?
      return nil
    end

    if !modbus_device.polled_by_plc?
      return nil
    end

    modbus_device.plc
  end

  # The behavior whose register-level logic governs this measurement point.
  #
  # For an MP on a Plc, it's the PLC's behavior. For an MP on a ModbusDevice
  # (either gateway-direct or PLC-relayed), it's the *peripheral's* own
  # behavior — not the host's. Relay encoding is a coordinate-level concern
  # (see #read_coordinates / #write_coordinates) and stays out of behaviors.
  #
  # Returns nil only if the MP has no owner at all (shouldn't happen in
  # valid data).
  def governing_behavior
    @governing_behavior ||= begin
      owner = modbus_device || plc
      owner ? ModbusBehaviors.for(owner) : nil
    end
  end

  def sync_read!
    coords = read_coordinates
    if coords.nil?
      return false
    end

    ModbusEndpointReadService.new(
      gateway:            coords.gateway,
      target_ip:          coords.target_ip,
      slave_id:           coords.slave_id,
      measurement_points: [self]
    ).call
  rescue VpnManagerClient::Error, Timeout::Error => e
    Rails.logger.warn("sync_read! failed for MP #{id}: #{e.class} - #{e.message}")
    false
  end

  # Synchronous single-MP write convenience. Mirrors sync_read! semantics:
  # returns true on success, false on failure (with logging). For batched or
  # user-action writes, prefer ModbusWriteService#bulk_write! directly so
  # you keep transactional control of the result.
  def sync_write!(value, context: nil)
    ModbusWriteService.new.bulk_write!(
      [{ measurement_point: self, value: value }],
      context: context
    )
    true
  rescue ModbusWriteService::WriteError, ModbusWriteService::ValidationError => e
    Rails.logger.warn("sync_write! failed for MP #{id}: #{e.class} - #{e.message}")
    false
  end

  private
    def register_template_matches_modbus_firmware_version
      if !register_template.present?
        return
      end

      owner = modbus_device || plc
      if !owner.present?
        return
      end

      if register_template.modbus_firmware_version_id != owner.modbus_firmware_version_id
        owner_label = modbus_device ? "device's" : "PLC's"
        errors.add(:register_template, "must belong to the #{owner_label} firmware version")
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

      if modbus_device
        errors.add(:measurement_subtype, 'must be present for active measurements on a device')
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

    def behavior_reachable_via_gateway?
      # Direct topology: the entity holds its own gateway_id
      # (a Plc, or a gateway-direct ModbusDevice).
      owner = modbus_device || plc
      if owner&.gateway_id.present?
        return true
      end

      # Relay topology: the ModbusDevice routes through a host PLC
      # that needs its own gateway.
      if modbus_device&.polled_by_plc?
        return modbus_device.plc&.gateway_id.present?
      end

      false
    end

    def trigger_behavior_sync
      behavior = governing_behavior
      if !behavior || behavior.mp_triggers.empty?
        return
      end

      # Cheap reachability gate: don't fire background syncs for entities
      # that have no wire path yet (e.g., a half-configured PLC without a
      # gateway, or a ModbusDevice whose host isn't on a gateway).
      if !behavior_reachable_via_gateway?
        return
      end

      behavior.trigger_from_mp_update(saved_changes.keys)
    end

    def sync_read_after_enable
      saved = saved_change_to_active
      if !saved
        return
      end

      if saved[0] != false || saved[1] != true
        return
      end

      sync_read!
    end

    def compute_live_display_value
      unit = effective_unit.to_s

      if register_template.category != 'counter'
        return { value: scaled_last_decoded_value, unit: unit }
      end
      return { value: scaled_last_decoded_value, unit: unit }

      recent = raw_values.order(sample_time: :desc).limit(2).to_a
      v1, v2 = recent

      if v1.nil?
        return { value: nil, unit: unit }
      end

      if v2.nil? || (elapsed = (v1.sample_time - v2.sample_time).to_f) == 0
        return { value: v1.scaled_value, unit: unit }
      end

      delta = v1.scaled_value - v2.scaled_value

      if delta < 0
        return { value: v1.scaled_value, unit: unit }
      end

      rate_unit = unit.present? ? "#{unit}/s" : '/s'
      { value: delta / elapsed, unit: rate_unit }
    end

    def fetch_group_points
      if !register_template.group_name.present?
        return []
      end

      scope = MeasurementPoint.none
      if modbus_device.present?
        scope = modbus_device.measurement_points
      elsif plc.present?
        scope = plc.measurement_points
      end

      scope
        .joins(:register_template)
        .where(register_templates: {
          modbus_firmware_version_id: register_template.modbus_firmware_version_id,
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

    def read_direct_coordinates
      if (!plc && !modbus_device) || !register_template
        return nil
      end

      modbus_entity = plc ? plc : modbus_device
      rt = register_template
      offset = modbus_entity.modbus_firmware_version.address_offset

      ModbusReadCoordinates.new(
        gateway:              modbus_entity.gateway,
        target_ip:            modbus_entity.private_ip,
        slave_id:             modbus_entity.slave_id,
        register_type:        rt.register_type,
        address:              rt.address + offset,
        count:                rt.address_count,
        bulk_strategy:        :bulk,
        template_bulk_group:  rt.bulk_read_group.presence,
        template_bulk_base:   rt.bulk_read_address.present? ? rt.bulk_read_address + offset : nil,
        template_bulk_offset: rt.bulk_read_offset
      )
    end

    def read_plc_relayed_coordinates
      if !modbus_device || !register_template
        return nil
      end

      host_plc = modbus_device.plc
      if !host_plc
        return nil
      end

      host = host_plc.modbus_firmware_version
      if !host&.host_capable?
        return nil
      end

      relay_address = modbus_device.relay_address_for(register_template)
      if relay_address.nil?
        return nil
      end

      strategy = host.relay_read_strategy
      if strategy.blank?
        return nil
      end

      ModbusReadCoordinates.new(
        gateway:                host_plc.gateway,
        target_ip:              host_plc.private_ip,
        slave_id:               host_plc.slave_id,
        register_type:          host.relay_register_type,
        address:                relay_address + host.address_offset,
        count:                  register_template.address_count,
        bulk_strategy:          strategy.to_sym,
        relay_slot_number:      modbus_device.slot_number,
        relay_modbus_device_id: modbus_device.id
      )
    end

    def write_coordinates_direct(entity)
      if !entity.gateway.present?
        return nil
      end
      offset = entity.modbus_firmware_version.address_offset

      ModbusWriteCoordinates.new(
        gateway:       entity.gateway,
        target_ip:     entity.private_ip,
        slave_id:      entity.slave_id,
        register_type: register_template.register_type,
        address:       register_template.address + offset
      )
    end

    def write_coordinates_via_relay_write
      device = modbus_device
      host = device.plc
      if !host&.gateway.present?
        return nil
      end

      host_version = host.modbus_firmware_version
      if !host_version&.host_capable?
        return nil
      end

      relay_address = device.relay_address_for(
        register_template,
        direction: ModbusDevice::WRITE_DIRECTION
      )
      if relay_address.nil?
        return nil
      end

      ModbusWriteCoordinates.new(
        gateway:       host.gateway,
        target_ip:     host.private_ip,
        slave_id:      host.slave_id,
        register_type: host_version.relay_register_type,
        address:       relay_address + host_version.address_offset
      )
    end
end
