# Concern for MeasurementPoint model.
# Contains ZERO PLC-specific logic — just observes changes and enqueues jobs.
#
# Include in your MeasurementPoint model:
#   include OutputControlCallbacks
#
module OutputControlCallbacks
  extend ActiveSupport::Concern

  included do
    after_save :enqueue_io_active_sync
    after_commit :enqueue_sensor_reference_cascade, on: :update
  end

  private
    def enqueue_io_active_sync
      if !plc_id.present?
        return
      end

      if !saved_change_to_active? && !saved_change_to_data_collection_enabled?
        return
      end

      IoActiveSyncJob.perform_async(plc_id)
    end

    # When any IO is deactivated, pass the interface's communication_type
    # and io_number to the cascade job. The behavior class figures out
    # what to do (or does nothing if the version doesn't support it).
    def enqueue_sensor_reference_cascade
      if !previous_changes.key?('active')
        return
      end

      old_active, new_active = previous_changes['active']

      if !old_active || new_active
        return
      end

      interface_info = resolve_interface_info
      if !interface_info.present?
        return
      end

      SensorReferenceCascadeJob.perform_async(
        plc_id,
        interface_info[:communication_type],
        interface_info[:io_number]
      )
    end

    # Returns { communication_type:, io_number: } for this measurement point's
    # interface, or nil if not on an interface.
    def resolve_interface_info
      result = register_template.interface_register_mappings
        .joins(:interface)
        .pluck('interfaces.communication_type', 'interfaces.io_number')
        .first
      if !result.present?
        return nil
      end

      { communication_type: result[0], io_number: result[1] }
    end
end
