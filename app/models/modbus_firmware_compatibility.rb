class ModbusFirmwareCompatibility < ApplicationRecord
  audited

  belongs_to :host_version, class_name: 'ModbusFirmwareVersion', foreign_key: :host_version_id
  belongs_to :peripheral_version, class_name: 'ModbusFirmwareVersion', foreign_key: :peripheral_version_id

  validates :host_version_id, uniqueness: { scope: :peripheral_version_id }
  validate :host_and_peripheral_differ
  validates :firmware_code,
    numericality: { only_integer: true, greater_than: 0 },
    uniqueness: { scope: :host_version_id },
    allow_nil: true

  def self.firmware_code_for(host_version_id:, peripheral_version_id:)
    find_by(
      host_version_id: host_version_id,
      peripheral_version_id: peripheral_version_id
    )&.firmware_code
  end

  private
    def host_and_peripheral_differ
      if host_version_id.present? && host_version_id == peripheral_version_id
        errors.add(:peripheral_version_id, "cannot equal host_version_id")
      end
    end
end
