class PlcWriteLog < ApplicationRecord
  self.record_timestamps = false

  SOURCES = %w[
    user
    system_sync
    sun_data_sync
    io_active_sync
    deactivation_cascade
    onetime_cleanup
    utc_offset_sync
    push_bitmask_sync
  ].freeze

  belongs_to :plc
  belongs_to :site
  belongs_to :user, optional: true
  belongs_to :measurement_point
  belongs_to :register_template

  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :batch_id, presence: true
  validates :created_at, presence: true

  before_create { self.created_at = Time.current }

  # Returns logs for all measurement points belonging to a specific interface
  # on a given PLC. Useful for building the activity log for a DO.
  scope :for_interface, ->(plc_id, interface_id) {
    joins(measurement_point: { register_template: :interface_register_mappings })
      .where(plc_id: plc_id)
      .where(interface_register_mappings: { interface_id: interface_id })
  }

  # Returns logs grouped by batch_id for display purposes.
  # Each batch represents a single user action or system event.
  def self.grouped_by_batch(logs = all)
    logs.order(created_at: :desc).group_by(&:batch_id)
  end

  def system_action?
    user_id.nil?
  end

  def user_action?
    user_id.present?
  end
end
