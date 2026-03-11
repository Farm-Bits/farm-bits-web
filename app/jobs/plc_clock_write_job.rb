class PlcClockWriteJob
  include Sidekiq::Job
  sidekiq_options queue: 'critical'

  def perform(plc_id)
    plc = Plc.includes(:gateway, :plc_version, site: :company).find_by(id: plc_id)
    if !plc&.operational?
      return
    end

    behavior = PlcBehaviors.for(plc)
    behavior.sync_clock!
    behavior.sync_utc_offset!
  rescue PlcWriteService::ConnectionError => e
    Rails.logger.error("[PlcClockWrite] PLC #{plc_id} unreachable: #{e.message}")
    Bugsnag.notify(e) { |r| r.severity = 'warning'; r.add_metadata(:plc, { plc_id: plc_id }) }
    raise
  rescue PlcWriteService::WriteError => e
    Rails.logger.error("[PlcClockWrite] PLC #{plc_id} write failed: #{e.message}")
    Bugsnag.notify(e) { |r| r.severity = 'error'; r.add_metadata(:plc, { plc_id: plc_id }) }
  rescue => e
    Rails.logger.error("[PlcClockWrite] PLC #{plc_id} error: #{e.class} - #{e.message}")
    Bugsnag.notify(e)
  end
end
