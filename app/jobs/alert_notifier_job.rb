# Sidekiq wrapper around AlertNotificationDispatcher. Enqueued by
# AlertTransitionApplier after each open or close commits.
#
# Re-loads the alert from the DB rather than trusting any in-memory
# state - by the time the job runs the alert may have been edited
# (e.g. closed by a subsequent reading after being opened).
#
class AlertNotifierJob
  include Sidekiq::Job
  sidekiq_options queue: 'critical', retry: 3

  def perform(alert_id, lifecycle)
    alert = Alert
      .includes(:alert_rule, :site, measurement_point: [:site, :register_template])
      .find_by(id: alert_id)
    if !alert
      Rails.logger.warn("AlertNotifierJob: alert #{alert_id} not found - skipping")
      return
    end

    AlertNotificationDispatcher.call(alert, lifecycle: lifecycle)
  rescue => e
    Rails.logger.error("AlertNotifierJob alert=#{alert_id}: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace&.first(10)&.join("\n"))
    Bugsnag.notify(e) do |report|
      report.severity = 'warning'
      report.add_metadata(:alert_notifier, { alert_id: alert_id, lifecycle: lifecycle })
    end
    raise
  end
end
