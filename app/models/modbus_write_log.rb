class ModbusWriteLog < ApplicationRecord
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

  belongs_to :target, polymorphic: true
  belongs_to :relay_host_plc, class_name: 'Plc', optional: true
  belongs_to :site
  belongs_to :user, optional: true
  belongs_to :measurement_point
  belongs_to :register_template

  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :batch_id, presence: true
  validates :created_at, presence: true
  validates :target_type, inclusion: { in: %w[Plc ModbusDevice] }

  before_create { self.created_at = Time.current }

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

  # Convenience: was this write transported via a host PLC's relay layer,
  # or did it go directly to the target?
  def relayed?
    relay_host_plc_id.present?
  end
end
