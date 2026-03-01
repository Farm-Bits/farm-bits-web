class PlcClockWriteJob
  include Sidekiq::Job
  sidekiq_options queue: 'critical'

  def perform(plc_id)
    plc = Plc.includes(:gateway, site: :company).find_by(id: plc_id)

    if !plc || !plc.active? || !plc.gateway || !plc.gateway.active? || !plc.site || !plc.site.company.active?
      return
    end

    clock_points = plc.measurement_points
      .joins(:register_template)
      .where(register_templates: { group_name: 'set_system_clock' })
      .includes(:register_template)
      .index_by { |mp| mp.register_template.group_role }

    all_roles_present = PlcClockSyncJob::REQUIRED_ROLES.all? { |role| clock_points.key?(role) }
    if !all_roles_present
      return
    end

    site_tz = plc.site&.time_zone_object || ActiveSupport::TimeZone['UTC']
    local_time = Time.current.in_time_zone(site_tz)

    time_writes = PlcClockSyncJob::TIME_COMPONENT_MAP.map do |role, value_proc|
      mp = clock_points[role]
      {
        measurement_point: mp,
        value: value_proc.call(local_time)
      }
    end

    client = VpnManagerClient.new
    response = client.bulk_write_registers(plc, time_writes)
    if !response[:success]
      raise VpnManagerClient::Error, "Clock bulk write failed: #{response[:error]}"
    end

    upload_mp = clock_points['upload_trigger']
    client.write_register(upload_mp, 1)
  rescue VpnManagerClient::ConnectionError => e
    Rails.logger.error("PlcClockWriteJob: PLC #{plc_id} unreachable: #{e.message}")
    Bugsnag.notify(e) do |report|
      report.severity = 'warning'
      report.add_metadata(:plc, { plc_id: plc_id })
    end
    raise
  rescue VpnManagerClient::NotFoundError => e
    Rails.logger.error("PlcClockWriteJob: PLC #{plc_id} not found: #{e.message}")
    Bugsnag.notify(e)
  rescue VpnManagerClient::Error => e
    Rails.logger.error("PlcClockWriteJob: PLC #{plc_id} write failed: #{e.message}")
    Bugsnag.notify(e)
  rescue => e
    Rails.logger.error("PlcClockWriteJob: PLC #{plc_id} error: #{e.class} - #{e.message}")
    Bugsnag.notify(e)
  end
end
