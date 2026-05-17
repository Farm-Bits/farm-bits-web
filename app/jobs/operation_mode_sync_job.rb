class OperationModeSyncJob
  include Sidekiq::Job
  sidekiq_options queue: 'critical'

  def perform(plc_id)
    plc = Plc.includes(:gateway, :modbus_firmware_version, site: :company).find_by(id: plc_id)
    if !plc&.operational?
      return
    end

    behavior = ModbusBehaviors.for(plc)
    behavior.cleanup_onetime_schedules!
    behavior.sync_io_active!
  rescue ModbusWriteService::ConnectionError => e
    Rails.logger.warn("[OperationModeSync] PLC #{plc_id} unreachable: #{e.message}")
  rescue ModbusWriteService::WriteError => e
    Rails.logger.error("[OperationModeSync] PLC #{plc_id} write failed: #{e.message}")
  end
end
