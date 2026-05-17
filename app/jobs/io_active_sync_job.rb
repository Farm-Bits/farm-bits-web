class IoActiveSyncJob
  include Sidekiq::Job
  sidekiq_options queue: 'critical'

  def perform(plc_id)
    plc = Plc.includes(:gateway, :modbus_firmware_version, site: :company).find_by(id: plc_id)
    if !plc&.operational?
      return
    end

    ModbusBehaviors.for(plc).sync_io_active!
  rescue ModbusWriteService::ConnectionError => e
    Rails.logger.warn("[IoActiveSync] PLC #{plc_id} unreachable: #{e.message}")
  rescue ModbusWriteService::WriteError => e
    Rails.logger.error("[IoActiveSync] PLC #{plc_id} write failed: #{e.message}")
  end
end
