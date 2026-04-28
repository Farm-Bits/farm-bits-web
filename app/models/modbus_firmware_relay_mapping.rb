class ModbusFirmwareRelayMapping < ApplicationRecord
  audited

  belongs_to :modbus_firmware_version
  belongs_to :register_template

  validates :modbus_firmware_version_id, uniqueness: { scope: :register_template_id }
  validates :relay_offset,
    presence: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :register_template_belongs_to_supported_peripheral
  validate :relay_offset_within_slot_size

  private
    def register_template_belongs_to_supported_peripheral
      if !modbus_firmware_version.present? || !register_template.present?
        return
      end

      host_firmware = modbus_firmware_version
      peripheral_id = register_template.modbus_firmware_version_id

      if host_firmware.id == peripheral_id
        errors.add(:register_template, 'cannot belong to the host firmware itself')
        return
      end

      supported = host_firmware.supported_peripheral_versions.exists?(id: peripheral_id)
      if !supported
        errors.add(:register_template, 'belongs to a firmware not declared as supported peripheral')
      end
    end

    def relay_offset_within_slot_size
      if !modbus_firmware_version&.relay_slot_size.present? || relay_offset.nil?
        return
      end

      template_count = register_template&.address_count || 1
      end_offset = relay_offset + template_count - 1
      if end_offset >= modbus_firmware_version.relay_slot_size
        errors.add(
          :relay_offset,
          "register would extend past slot boundary (offset + count = #{end_offset + 1}, slot_size = #{modbus_firmware_version.relay_slot_size})"
        )
      end
    end
end
