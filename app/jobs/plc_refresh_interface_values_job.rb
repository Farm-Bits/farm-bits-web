class PlcRefreshInterfaceValuesJob
  include Sidekiq::Job
  sidekiq_options queue: 'default', retry: false

  def perform(plc_id)
    plc = Plc.includes(:gateway).find_by(id: plc_id)
    if !plc || !plc.gateway
      return
    end

    measurement_points = plc.measurement_points
      .joins(:register_template)
      .where(register_templates: {
        category: MeasurementSubtype::DATA_CATEGORIES,
        user_visibility: 'visible'
      })
      .includes(:register_template)

    PlcReadService.new(plc, measurement_points).call
  rescue VpnManagerClient::ConnectionError => e
    Rails.logger.warn("PLC #{plc_id} refresh connection error: #{e.message}")
  rescue => e
    Rails.logger.error("PLC #{plc_id} refresh error: #{e.class} - #{e.message}")
    Bugsnag.notify(e) do |report|
      report.severity = 'info'
      report.add_metadata(:plc, { plc_id: plc_id })
    end
  end
end
