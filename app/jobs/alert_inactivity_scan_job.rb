# For each active inactivity rule, computes whether its MP has been silent for
# longer than the rule's inactivity_seconds threshold.
#
# Synthesizes AlertEvaluator::Transition records and applies them via
# the same AlertTransitionApplier used by value-driven evaluation, so
# inactivity alerts share the snapshot/notification path with the rest.
#
# Recommended cron: every 60 seconds. Granularity below that is
# wasteful - inactivity_seconds is typically minutes to hours.
#
class AlertInactivityScanJob
  include Sidekiq::Job
  sidekiq_options queue: 'default', retry: 3

  def perform
    rules = active_inactivity_rules
    if rules.empty?
      return
    end

    open_by_rule_id      = open_alerts_for(rules).index_by(&:alert_rule_id)
    candidate_by_rule_id = candidates_for(rules).index_by(&:alert_rule_id)

    transitions = rules.flat_map do |rule|
      evaluate(rule, open_by_rule_id[rule.id], candidate_by_rule_id[rule.id])
    end

    if transitions.empty?
      return
    end

    AlertTransitionApplier.call(transitions)
  rescue => e
    Rails.logger.error("AlertInactivityScanJob: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace&.first(10)&.join("\n"))
    Bugsnag.notify(e) { |r| r.severity = 'warning' }
    raise
  end

  private
    def active_inactivity_rules
      AlertRule
        .active
        .where(condition_type: 'inactivity')
        .includes(measurement_point: [:register_template, :site])
        .to_a
        .select { |r| r.measurement_point.present? }
    end

    def open_alerts_for(rules)
      Alert
        .open
        .where(alert_rule_id: rules.map(&:id))
        .to_a
    end

    def candidates_for(rules)
      AlertCandidate
        .where(alert_rule_id: rules.map(&:id))
        .to_a
    end

    def evaluate(rule, open_alert, candidate)
      now = Time.current
      mp  = rule.measurement_point

      predicate_true = inactive?(mp, rule, now)

      if predicate_true
        return handle_predicate_true(rule, open_alert, candidate, now)
      end

      handle_predicate_false(rule, open_alert, candidate, now)
    end

    # MP is inactive when its last reading is older than the rule's
    # inactivity_seconds. An MP that has *never* reported is considered
    # inactive immediately - this is intentional, since "silent since
    # creation" is exactly the situation an inactivity alert exists for.
    def inactive?(mp, rule, now)
      last_at = mp.last_decoded_value_at

      if last_at.nil?
        return now - mp.created_at >= rule.inactivity_seconds
      end

      now - last_at >= rule.inactivity_seconds
    end

    def handle_predicate_true(rule, open_alert, candidate, now)
      if open_alert.present?
        return []
      end

      if !rule.has_dwell?
        return [transition(:open_alert, rule: rule, value: inactivity_value(rule), at: now)]
      end

      if candidate.present?
        if candidate.dwell_elapsed?(at: now)
          return [transition(:open_alert, rule: rule, candidate: candidate, value: inactivity_value(rule), at: now)]
        end

        return []
      end

      [transition(:start_candidate, rule: rule, value: inactivity_value(rule), at: now)]
    end

    def handle_predicate_false(rule, open_alert, candidate, now)
      transitions = []

      if candidate.present?
        transitions << transition(:cancel_candidate, rule: rule, candidate: candidate, at: now)
      end

      if open_alert.present?
        transitions << transition(
          :close_alert,
          rule:  rule,
          alert: open_alert,
          value: rule.measurement_point&.last_decoded_value,
          at:    now
        )
      end

      transitions
    end

    # For inactivity, "value" in the snapshot is the elapsed-seconds
    # count at the moment of firing - useful in the email body
    # ("Tank temperature has been silent for 12 minutes").
    def inactivity_value(rule)
      mp = rule.measurement_point
      last_at = mp&.last_decoded_value_at || mp&.created_at
      if last_at.nil?
        return nil
      end

      (Time.current - last_at).to_i.to_s
    end

    def transition(kind, rule:, alert: nil, candidate: nil, value: nil, at:)
      AlertEvaluator::Transition.new(
        kind:       kind,
        alert_rule: rule,
        alert:      alert,
        candidate:  candidate,
        value:      value,
        at:         at
      )
    end
end
