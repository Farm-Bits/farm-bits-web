class Plc < ApplicationRecord
  audited

  belongs_to :model
  belongs_to :plc_version
  belongs_to :terminal, optional: true
  belongs_to :client, optional: true

  encrypts :username
  encrypts :password
  encrypts :web_username
  encrypts :web_password

  has_many :measurement_points, dependent: :destroy

  validates :label, presence: true
  validates :name, presence: true
  validates :serial_number, presence: true, uniqueness: true
  validates :slave,
    presence: true,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: 247,
      message: 'must be between 1 and 247 (Modbus specification)'
    }
  validates :private_ip, format: {
    with: /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/
  }
  validates :private_ip, uniqueness: {
    scope: :terminal_id,
    message: 'is already assigned to another PLC on this terminal',
    conditions: -> { where.not(terminal_id: nil) }
  }, if: -> { terminal_id.present? }
  validates :username, presence: true
  validates :password, presence: true
  validates :web_username, presence: true
  validates :web_password, presence: true
  validate :model_is_plc_type
  validate :client_matches_terminal_client, if: -> { terminal_id.present? && client_id.present? }

  def handler
    plc_version.handler_for(self)
  end

  def touch_last_seen!(timestamp = Time.current)
    update_column(:last_seen_at, timestamp)
  end

  def poll!
    Polling::PlcPoller.new(self).poll!
  end

  private
    def model_is_plc_type
      if !model.present?
        return
      end

      if !model.device_type_plc?
        errors.add(:model, 'must be a PLC model')
      end
    end

    def client_matches_terminal_client
      if terminal.client_id != client_id
        errors.add(:client, 'must match the terminal client')
      end
    end
end
