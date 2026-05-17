class ModbusDevice < ApplicationRecord
  audited

  READ_DIRECTION  = 'read'.freeze
  WRITE_DIRECTION = 'write'.freeze

  belongs_to :model
  belongs_to :modbus_firmware_version
  belongs_to :plc,     optional: true
  belongs_to :site,    optional: true
  belongs_to :gateway, optional: true

  has_many :measurement_points, dependent: :destroy

  validates :name, presence: true
  validates :label, uniqueness: true, allow_nil: true
  validates :slave_id,
    presence: true,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: 247,
      message: 'must be between 1 and 247 (Modbus specification)'
    }
  validates :private_ip, presence: true, format: {
    with: /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/
  }, if: -> { gateway_id.present? }
  validates :private_ip, uniqueness: {
    scope: :gateway_id,
    message: 'is already assigned to another PLC on this gateway',
    conditions: -> { where.not(gateway_id: nil) }
  }, if: -> { gateway_id.present? }
  validate :model_is_modbus_device_type
  validate :modbus_firmware_version_belongs_to_model
  validate :plc_firmware_supports_hosting
  validate :firmware_code_defined_for_plc_connection
  validate :gateway_and_plc_mutually_exclusive
  validate :slot_number_consistent_with_plc
  validate :slot_number_within_range
  validate :modbus_firmware_version_supported_by_plc_firmware
  validate :site_matches_connection

  attr_accessor :disable_initial_read

  before_validation :auto_assign_slot_number
  before_validation :derive_site_from_connection
  before_save :clear_slot_when_disconnected
  after_create :create_measurement_points_from_templates
  after_update :sync_measurement_points_site
  after_commit :enqueue_initial_read, on: :create, if: -> { active? && polled_by_gateway? }
  after_commit :enqueue_initial_read, on: :update, if: -> { saved_change_to_active? && active? }

  def polled_by_plc?
    plc_id.present?
  end

  def polled_by_gateway?
    gateway_id.present? && plc_id.nil?
  end

  def operational?
    if !active?
      return false
    end

    if !site&.company&.active?
      return false
    end

    if polled_by_gateway?
      return gateway&.active? == true
    end

    if polled_by_plc?
      return plc&.active? == true && plc.gateway&.active? == true
    end

    false
  end

  def firmware_code
    if !plc.present? || !plc.modbus_firmware_version.present?
      return nil
    end

    ModbusFirmwareCompatibility.firmware_code_for(
      host_version_id:       plc.modbus_firmware_version_id,
      peripheral_version_id: modbus_firmware_version_id
    )
  end

  def touch_last_seen!(timestamp = Time.current)
    update_column(:last_seen_at, timestamp)
  end

  # Computes the wire address (in the host PLC's relay address space) that
  # corresponds to the given register template, in the requested direction.
  #
  # `direction` is 'read_from_peripheral' (default; preserves prior behaviour)
  # or 'write_to_peripheral' (looks up the write-buffer mapping).
  #
  # Returns nil if:
  #   - this device is not PLC-relayed
  #   - the host's firmware is not host_capable
  #   - no relay mapping exists for this register_template + direction
  def relay_address_for(register_template, direction: READ_DIRECTION)
    if !polled_by_plc?
      return nil
    end

    host_version = plc.modbus_firmware_version
    if !host_version&.host_capable?
      return nil
    end

    mapping = host_version.relay_mappings.detect do |m|
      m.register_template_id == register_template.id && m.direction == direction
    end
    if mapping.nil?
      return nil
    end

    host_version.relay_slot_base + (host_version.relay_slot_size * (slot_number - 1)) + mapping.relay_offset
  end

  private
    def model_is_modbus_device_type
      if !model.present?
        return
      end

      if model.device_type != 'modbus_device'
        errors.add(:model, 'must be a Modbus device model')
      end
    end

    def modbus_firmware_version_belongs_to_model
      if !model.present? || !modbus_firmware_version.present?
        return
      end

      if modbus_firmware_version.model_id != model_id
        errors.add(:modbus_firmware_version, "must belong to the selected model (#{model.full_name})")
      end
    end

    def plc_firmware_supports_hosting
      if !plc.present? || !plc.modbus_firmware_version.present?
        return
      end

      if !plc.modbus_firmware_version.host_capable?
        errors.add(:plc, "firmware does not support hosting external Modbus devices")
      end
    end

    def firmware_code_defined_for_plc_connection
      if !plc.present? || !modbus_firmware_version.present? || !plc.modbus_firmware_version.present?
        return
      end

      if firmware_code.nil?
        errors.add(
          :base,
          "no firmware_code defined on the compatibility between the PLC's firmware " \
          "(#{plc.modbus_firmware_version.name}) and this device's firmware " \
          "(#{modbus_firmware_version.name}). The PLC cannot poll peripherals without it."
        )
      end
    end

    def gateway_and_plc_mutually_exclusive
      if gateway_id.present? && plc_id.present?
        errors.add(:base, "cannot be connected to both a gateway and a PLC")
      end
    end

    def slot_number_consistent_with_plc
      if plc_id.present? && slot_number.nil?
        errors.add(:slot_number, "is required when connected to a PLC")
      end

      if plc_id.nil? && slot_number.present?
        errors.add(:slot_number, "must be blank when not connected to a PLC")
      end
    end

    def slot_number_within_range
      if slot_number.nil? || !plc.present?
        return
      end

      max = plc.modbus_firmware_version&.relay_max_slots
      if max.nil?
        return
      end

      if !slot_number.between?(1, max)
        errors.add(:slot_number, "must be between 1 and #{max}")
      end
    end

    def modbus_firmware_version_supported_by_plc_firmware
      if !plc.present? || !modbus_firmware_version.present? || !plc.modbus_firmware_version.present?
        return
      end

      host_version = plc.modbus_firmware_version
      if !host_version.supported_peripheral_versions.exists?(id: modbus_firmware_version_id)
        errors.add(
          :modbus_firmware_version,
          "is not supported by the PLC's firmware (#{host_version.name})"
        )
      end
    end

    def site_matches_connection
      if plc.present? && site_id.present? && plc.site_id.present? && site_id != plc.site_id
        errors.add(:site, "must match the connected PLC's site")
      end

      if gateway.present? && site_id.present? && gateway.site_id.present? && site_id != gateway.site_id
        errors.add(:site, "must match the connected gateway's site")
      end
    end

    def auto_assign_slot_number
      if plc_id.blank? || slot_number.present?
        return
      end

      if plc.nil? || plc.modbus_firmware_version.nil? || !plc.modbus_firmware_version.host_capable?
        return
      end

      max   = plc.modbus_firmware_version.relay_max_slots
      taken = ModbusDevice.where(plc_id: plc_id).where.not(id: id).pluck(:slot_number).compact.to_set
      free  = (1..max).find { |s| !taken.include?(s) }

      if free.nil?
        errors.add(:plc, "has no free slots (limit: #{max})")
      end

      self.slot_number = free
    end

    def derive_site_from_connection
      if site_id.present?
        return
      end

      if plc&.site_id.present?
        self.site_id = plc.site_id
      elsif gateway&.site_id.present?
        self.site_id = gateway.site_id
      end
    end

    def clear_slot_when_disconnected
      if plc_id.nil? && slot_number.present?
        self.slot_number = nil
      end
    end

    def create_measurement_points_from_templates
      if !modbus_firmware_version.present?
        return
      end

      modbus_firmware_version.register_templates.find_each do |template|
        measurement_points.create!(
          name:                  template.name,
          description:           template.description,
          position:              template.position,
          active:                !MeasurementSubtype::DATA_CATEGORIES.include?(template.category),
          measurement_subtype:   template.default_measurement_subtype,
          register_template:     template,
          site:                  site
        )
      end
    end

    def sync_measurement_points_site
      update_attrs = {}
      if saved_change_to_site_id?
        update_attrs[:site_id] = site_id
      end

      if saved_change_to_plc_id?
        update_attrs[:plc_id] = plc_id
      end

      if !update_attrs.empty?
        measurement_points.update_all(update_attrs)
      end
    end

    def enqueue_initial_read
      if disable_initial_read
        return
      end

      ModbusRefreshJob.perform_async('ModbusDevice', id)
    end
end
