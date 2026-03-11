class SunDataPlcWriteJob
  include Sidekiq::Job
  sidekiq_options queue: 'critical'

  def perform(plc_id)
    plc = Plc.includes(:gateway, :plc_version, site: :company).find_by(id: plc_id)
    if !plc&.operational?
      return
    end

    today_sun = plc.site&.site_sun_data&.find_by(date: Date.current)
    if !today_sun.present?
      return
    end

    sunrise_minutes = time_to_minutes(today_sun.sunrise)
    sunset_minutes = time_to_minutes(today_sun.sunset)
    if !sunrise_minutes.present? || !sunset_minutes.present?
      return
    end

    PlcBehaviors.for(plc).sync_sun_data!(sunrise_minutes, sunset_minutes)
  rescue PlcWriteService::ConnectionError => e
    Rails.logger.warn("[SunDataPlcWrite] PLC #{plc_id} unreachable: #{e.message}")
  rescue PlcWriteService::WriteError => e
    Rails.logger.error("[SunDataPlcWrite] PLC #{plc_id} write failed: #{e.message}")
  end

  private
    def time_to_minutes(time_str)
      if !time_str.present?
        return nil
      end

      parts = time_str.to_s.split(':')

      if parts.length < 2
        return nil
      end

      parts[0].to_i * 60 + parts[1].to_i
    end
end
