# Evaluates value-driven alert rules for a measurement point given a
# value transition. Enqueued by BulkRecordingService after each batch
# of readings is persisted.
#
# old_value / new_value are passed as strings (the same form
# last_decoded_value is stored in) and decoded by the rule's predicate
# logic. Both are nullable - first-ever reading has old_value = nil.
#
class AlertEvaluationJob
  include Sidekiq::Job
  sidekiq_options queue: 'default', retry: 3

  def perform(measurement_point_id, old_value, new_value, sample_time_iso)
    mp = MeasurementPoint
      .includes(:register_template, :measurement_subtype, :site)
      .find_by(id: measurement_point_id)
    if !mp
      return
    end

    transitions = AlertEvaluator.call(
      measurement_point: mp,
      old_value:         old_value,
      new_value:         new_value,
      at:                Time.parse(sample_time_iso)
    )

    if transitions.empty?
      return
    end

    AlertTransitionApplier.call(transitions)
  rescue => e
    Rails.logger.error("AlertEvaluationJob mp=#{measurement_point_id}: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace&.first(10)&.join("\n"))
    Bugsnag.notify(e) do |report|
      report.severity = 'warning'
      report.add_metadata(:alert_evaluation, {
        measurement_point_id: measurement_point_id,
        old_value:            old_value,
        new_value:            new_value
      })
    end
    raise
  end
end
