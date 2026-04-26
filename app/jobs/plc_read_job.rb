class PlcReadJob
  include Sidekiq::Job
  sidekiq_options queue: 'default', retry: 3

  def perform(plc_id)
    plc = Plc.includes(:gateway, :modbus_firmware_version, site: :company).find_by(id: plc_id)
    if !plc&.operational?
      return
    end

    measurement_points = plc.measurement_points
      .where(active: true, data_collection_enabled: true)
      .includes(:register_template)
      .select { |mp| mp.needs_polling? }
    if measurement_points.empty?
      return
    end

    PlcReadService.new(plc, measurement_points).call
  rescue VpnManagerClient::ConnectionError => e
    Rails.logger.error("PLC #{plc_id} connection error: #{e.message}")
    raise
  rescue VpnManagerClient::NotFoundError => e
    Rails.logger.error("PLC #{plc_id} not found on VPN manager: #{e.message}")
    raise
  rescue => e
    Rails.logger.error("PLC #{plc_id} polling error: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace&.first(10)&.join("\n"))
    Bugsnag.notify(e) do |report|
      report.severity = 'warning'
      report.add_metadata(:plc, { plc_id: plc_id })
    end
  end
end
