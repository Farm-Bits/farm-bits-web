class Terminal < ApplicationRecord
  audited

  belongs_to :model
  belongs_to :site, optional: true

  encrypts :username
  encrypts :password

  has_many :plcs, dependent: :nullify
  accepts_nested_attributes_for :plcs, :allow_destroy => true

  validates :label, presence: true
  validates :name, presence: true
  validates :imei, presence: true, uniqueness: true
  validates :serial_number, presence: true, uniqueness: true
  validates :iccid, uniqueness: true, allow_blank: true
  validates :phone_number, uniqueness: true, allow_blank: true
  validates :private_ip, format: { with: /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/ }
  validates :username, presence: true
  validates :password, presence: true
  validate :model_is_terminal_type

  after_update :remove_plcs_if_deactivated, if: -> { saved_change_to_active? && !active? }

  def full_name
    parts = []
    parts << manufacturer_name if model.present?
    parts << model_name if model.present?
    parts << "(#{display_identifier})"
    parts.join(' ')
  end

  def plc_assignments=(plc_assignments_params)
    ActiveRecord::Base.transaction do
      plcs.update_all(active: false, terminal_id: nil)

      plc_assignments_params.each do |assignment|
        plc = Plc.find(assignment[:id])
        plc.update!(assignment.merge(active: true, terminal_id: id))
      end
    end
  end

  def touch_last_seen!(timestamp = Time.current)
    update_column(:last_seen_at, timestamp)
  end

  private
    def model_is_terminal_type
      if !model.present?
        return
      end

      if model.device_type != 'terminal'
        errors.add(:model, 'must be a terminal model')
      end
    end

    def remove_plcs_if_deactivated
      plcs.update_all(active: false, terminal_id: nil)
    end
end
