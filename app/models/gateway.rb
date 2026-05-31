class Gateway < ApplicationRecord
  audited

  CONNECTION_STATUSES = %w[unknown connected disconnected].freeze
  UNADDRESSABLE_STATUSES = %w[disconnected].freeze

  belongs_to :model
  belongs_to :site, optional: true

  encrypts :password

  has_many :plcs, dependent: :nullify
  accepts_nested_attributes_for :plcs, :allow_destroy => true

  validates :label, presence: true, uniqueness: true
  validates :name, presence: true
  validates :imei, presence: true, uniqueness: true
  validates :serial_number, presence: true, uniqueness: true
  validates :iccid, uniqueness: true, allow_blank: true
  validates :phone_number, uniqueness: true, allow_blank: true
  validates :private_ip, format: { with: /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/ }
  validates :username, presence: true
  validates :password, presence: true
  validate :model_is_gateway_type

  enum :connection_status, CONNECTION_STATUSES.index_with(&:itself)

  after_update :remove_plcs_if_deactivated, if: -> { saved_change_to_active? && !active? }

  scope :addressable, -> { where.not(connection_status: UNADDRESSABLE_STATUSES) }

  def full_name
    parts = []
    parts << manufacturer_name if model.present?
    parts << model_name if model.present?
    parts << "(#{display_identifier})"
    parts.join(' ')
  end

  def apply_status!(new_status, status_updated_at: Time.current)
    new_status = new_status.to_s

    if !CONNECTION_STATUSES.include?(new_status)
      raise ArgumentError, "Unknown connection_status: #{new_status}"
    end

    # Ignore out-of-order updates (e.g. a slow pull arriving after a fresh push).
    if connection_status_updated_at.present? && status_updated_at < connection_status_updated_at
      return false
    end

    previous_status = connection_status
    update!(
      connection_status: new_status,
      connection_status_updated_at: status_updated_at
    )

    if previous_status != new_status
      handle_connection_status_transition(previous_status, new_status)
    end

    true
  end

  def plc_assignments=(plc_assignments_params)
    ActiveRecord::Base.transaction do
      plcs.update_all(active: false, gateway_id: nil)

      plc_assignments_params.each do |assignment|
        plc = Plc.find(assignment[:id])
        plc.update!(assignment.merge(active: true, gateway_id: id))
      end
    end
  end

  def addressable?
    !connection_status.in?(UNADDRESSABLE_STATUSES)
  end

  def touch_last_seen!(timestamp = Time.current)
    update_column(:last_seen_at, timestamp)
  end

  private
    def model_is_gateway_type
      if !model.present?
        return
      end

      if model.device_type != 'gateway'
        errors.add(:model, 'must be a gateway model')
      end
    end

    def remove_plcs_if_deactivated
      plcs.update_all(active: false, gateway_id: nil)
    end

    def handle_connection_status_transition(previous_status, new_status)
      # TODO: trigger gateway connectivity notification job/service here.
      #   went_offline?  = previous_status == 'connected' && new_status.in?(%w[disconnected revoked])
      #   came_online?   = previous_status != 'connected' && new_status == 'connected'
      # Notification recipients/channel TBD — do not build here.
    end
end
