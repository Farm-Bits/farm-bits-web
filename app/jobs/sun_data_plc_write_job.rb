class SunDataPlcWriteJob
  include Sidekiq::Job
  sidekiq_options queue: 'critical'

  def perform(plc_id)
    plc = Plc.includes(:gateway, :modbus_firmware_version, site: :company).find_by(id: plc_id)
    if !plc&.operational?
      return
    end

    today_sun = plc.site&.site_sun_data&.find_by(date: Date.current)
    if !today_sun.present?
      return
    end

    sunrise_minutes = today_sun.sunrise.hour * 60 + today_sun.sunrise.min
    sunset_minutes = today_sun.sunset.hour * 60 + today_sun.sunset.min
    if !sunrise_minutes.present? || !sunset_minutes.present?
      return
    end

    PlcBehaviors.for(plc).sync_sun_data!(sunrise_minutes, sunset_minutes)
  rescue ModbusWriteService::ConnectionError => e
    Rails.logger.warn("[SunDataPlcWrite] PLC #{plc_id} unreachable: #{e.message}")
  rescue ModbusWriteService::WriteError => e
    Rails.logger.error("[SunDataPlcWrite] PLC #{plc_id} write failed: #{e.message}")
  end
end
