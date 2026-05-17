class SensorReferenceCascadeJob
  include Sidekiq::Job
  sidekiq_options queue: 'critical'

  def perform(plc_id, communication_type, io_number)
    plc = Plc.includes(:gateway, :modbus_firmware_version, site: :company).find_by(id: plc_id)
    if !plc&.operational?
      return
    end

    ModbusBehaviors.for(plc).cascade_sensor_deactivation!(communication_type, io_number)
  rescue ModbusWriteService::ConnectionError => e
    Rails.logger.warn("[SensorCascade] PLC #{plc_id} unreachable: #{e.message}")
  rescue ModbusWriteService::WriteError => e
    Rails.logger.error("[SensorCascade] PLC #{plc_id} write failed: #{e.message}")
  end
end
