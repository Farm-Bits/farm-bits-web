class PlcInitialReadJob
  include Sidekiq::Job
  sidekiq_options queue: 'default', retry: 3

  def perform(plc_id)
    plc = Plc.includes(:gateway).find_by(id: plc_id)
    if !plc || !plc.gateway
      return
    end

    measurement_points = MeasurementPoint
      .joins(:register_template, plc: { gateway: { site: :company } })
      .where(register_templates: { user_visibility: 'visible' })
      .where(plcs: { id: plc_id })
      .includes(:register_template, register_template: { interface_register_mappings: :interface })
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
