class ModbusFirmwareRelayMapping < ApplicationRecord
  audited

  belongs_to :modbus_firmware_version
  belongs_to :register_template

  DIRECTIONS = %w[read write].freeze

  validates :relay_offset, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :direction, presence: true, inclusion: { in: DIRECTIONS }
  validates :register_template_id, uniqueness: {
    scope: [:modbus_firmware_version_id, :direction],
    message: ->(object, data) {
      "already has a #{object.direction} mapping for register " \
      "'#{object.register_template&.name}' on this firmware version"
    }
  }
  validate :register_template_belongs_to_same_firmware_version
  validate :write_direction_requires_writable_template

  def read_direction?
    direction == 'read'
  end

  def write_direction?
    direction == 'write'
  end

  private
    def register_template_belongs_to_same_firmware_version
      if !register_template.present? || !modbus_firmware_version.present?
        return
      end

      if register_template.modbus_firmware_version_id == modbus_firmware_version_id
        errors.add(:register_template, 'must belong to a peripheral firmware version, not the host itself')
        return
      end

      supported_ids = modbus_firmware_version.supported_peripheral_versions.pluck(:id)
      if !supported_ids.include?(register_template.modbus_firmware_version_id)
        errors.add(
          :register_template,
          "must belong to a firmware version supported as a peripheral by " \
          "'#{modbus_firmware_version.name}'"
        )
      end
    end

    def write_direction_requires_writable_template
      if !write_direction? || !register_template.present?
        return
      end

      if register_template.read_only?
        errors.add(
          :direction,
          "cannot be 'write' for a read-only register template"
        )
      end
    end
end
