class SensorReferenceCascadeJob
  include Sidekiq::Job
  sidekiq_options queue: 'critical'

  def perform(plc_id, communication_type, io_number)
    plc = Plc.includes(:gateway, :modbus_firmware_version, site: :company).find_by(id: plc_id)
    if !plc&.operational?
      return
    end

    PlcBehaviors.for(plc).cascade_sensor_deactivation!(communication_type, io_number)
  rescue PlcWriteService::ConnectionError => e
    Rails.logger.warn("[SensorCascade] PLC #{plc_id} unreachable: #{e.message}")
  rescue PlcWriteService::WriteError => e
    Rails.logger.error("[SensorCascade] PLC #{plc_id} write failed: #{e.message}")
  end
end
