# Applies a list of AlertEvaluator::Transition records to the database
# and enqueues notifications for the ones that need them.
#
# All transitions for a single MP evaluation are applied in one
# transaction. Notifications are enqueued *after* the transaction
# commits, so a failed write never produces a phantom notification.
#
# Returns the list of newly-opened and newly-closed alerts so callers
# can introspect what changed (used by tests/diagnostics; not required
# for normal operation).
#
class AlertTransitionApplier
  Result = Struct.new(:opened, :closed, keyword_init: true) do
    def changed?
      opened.any? || closed.any?
    end
  end

  def self.call(transitions)
    new(transitions).call
  end

  def initialize(transitions)
    @transitions = transitions
  end

  def call
    if @transitions.empty?
      return Result.new(opened: [], closed: [])
    end

    opened = []
    closed = []

    ApplicationRecord.transaction do
      @transitions.each do |t|
        case t.kind
        when :open_alert
          opened << apply_open(t)
        when :close_alert
          closed << apply_close(t)
        when :start_candidate
          apply_start_candidate(t)
        when :cancel_candidate
          apply_cancel_candidate(t)
        end
      end
    end

    enqueue_notifications(opened, :opened)
    enqueue_notifications(closed, :closed)

    Result.new(opened: opened, closed: closed)
  end

  private
    def apply_open(transition)
      alert = Alert.build_from_rule(transition.alert_rule, started_at: transition.at)
      alert.started_value = serialize_value(transition.alert_rule, transition.value)
      alert.save!

      if transition.candidate.present?
        transition.candidate.destroy!
      end

      alert
    end

    def apply_close(transition)
      alert = transition.alert
      alert.update!(
        ended_at:    transition.at,
        ended_value: serialize_value(transition.alert_rule, transition.value)
      )
      alert
    end

    def apply_start_candidate(transition)
      AlertCandidate.create!(
        alert_rule:              transition.alert_rule,
        predicate_first_true_at: transition.at
      )
    rescue ActiveRecord::RecordNotUnique
      # Concurrent evaluation already created one. Harmless.
    end

    def apply_cancel_candidate(transition)
      transition.candidate.destroy!
    end

    # Same string serialization as MeasurementPoint#serialize_for_storage,
    # but reached via the rule's MP so it works even when the alert's
    # measurement_point FK is nil after a deletion. Booleans become
    # '0'/'1', everything else gets to_s.
    def serialize_value(rule, value)
      if value.nil?
        return nil
      end

      mp = rule.measurement_point
      if mp.present?
        return mp.serialize_for_storage(value)
      end

      value.to_s
    end

    def enqueue_notifications(alerts, lifecycle_event)
      alerts.each do |alert|
        AlertNotifierJob.perform_async(alert.id, lifecycle_event.to_s)
      end
    end
end
