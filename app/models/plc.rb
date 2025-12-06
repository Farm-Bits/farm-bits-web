class Plc < ApplicationRecord
  audited

  belongs_to :plc_version
  belongs_to :terminal, optional: true
  belongs_to :client, optional: true

  encrypts :username
  encrypts :password

  validates :label, presence: true
  validates :name, presence: true
  validates :serial_number, presence: true, uniqueness: { case_sensitive: false }
  validates :slave,
    presence: true,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: 247,
      message: 'must be between 1 and 247 (Modbus specification)'
    }
  validates :private_ip,
    uniqueness: {
      scope: :terminal_id,
      message: 'is already assigned to another PLC on this terminal',
      conditions: -> { where.not(terminal_id: nil) }
    },
    if: -> { terminal_id.present? }
  validate :private_ip_must_be_valid

  private
    def private_ip_must_be_valid
      if private_ip.blank?
        return
      end

      IPAddr.new(private_ip)
    rescue IPAddr::InvalidAddressError
      errors.add(:private_ip, "must be a valid IP address")
    end
end
