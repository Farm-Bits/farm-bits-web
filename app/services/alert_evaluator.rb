# Pure decision engine. Given a measurement point's value transition
# and the current state (active rules, open alerts, candidates),
# returns the list of state transitions that should be applied.
#
# No DB writes, no side effects. The opener/closer services in step 6
# translate these transitions into row changes and notifications.
#
# Transitions:
#   :open_alert       - predicate true, no dwell or dwell elapsed, no open alert
#   :close_alert      - predicate false, open alert exists
#   :start_candidate  - predicate true, no candidate, dwell required
#   :cancel_candidate - predicate false, candidate exists
#
# Inactivity rules are evaluated separately by AlertInactivityScanJob;
# this evaluator only handles status_change and threshold rules driven
# by value updates.
#
class AlertEvaluator
  Transition = Struct.new(:kind, :alert_rule, :alert, :candidate, :value, :at, keyword_init: true)

  def self.call(measurement_point:, old_value:, new_value:, at: Time.current)
    new(measurement_point, old_value, new_value, at).call
  end

  def initialize(measurement_point, old_value, new_value, at)
    @measurement_point = measurement_point
    @old_value         = old_value
    @new_value         = new_value
    @at                = at
  end

  def call
    rules = active_value_driven_rules
    if rules.empty?
      return []
    end

    open_by_rule_id      = open_alerts.index_by(&:alert_rule_id)
    candidate_by_rule_id = candidates.index_by(&:alert_rule_id)

    rules.flat_map do |rule|
      evaluate(rule, open_by_rule_id[rule.id], candidate_by_rule_id[rule.id])
    end
  end

  private
    attr_reader :measurement_point, :old_value, :new_value, :at

    def active_value_driven_rules
      AlertRule
        .active
        .where(measurement_point_id: measurement_point.id)
        .where(condition_type: %w[status_change threshold])
        .to_a
    end

    def open_alerts
      Alert
        .open
        .where(alert_rule_id: active_value_driven_rules.map(&:id))
        .to_a
    end

    def candidates
      AlertCandidate
        .where(alert_rule_id: active_value_driven_rules.map(&:id))
        .to_a
    end

    # Single-rule decision tree. Returns 0 or 1 transitions.
    def evaluate(rule, open_alert, candidate)
      predicate_true = predicate_true_for?(rule)

      if predicate_true
        return handle_predicate_true(rule, open_alert, candidate)
      end

      handle_predicate_false(rule, open_alert, candidate)
    end

    def handle_predicate_true(rule, open_alert, candidate)
      if open_alert.present?
        # Already firing - stay firing, do nothing.
        return []
      end

      if !rule.has_dwell?
        return [transition(:open_alert, rule: rule, value: new_value)]
      end

      if candidate.present?
        if candidate.dwell_elapsed?(at: at)
          return [transition(:open_alert, rule: rule, candidate: candidate, value: new_value)]
        end

        # Still waiting on dwell.
        return []
      end

      # Dwell required, no candidate yet - start the clock.
      [transition(:start_candidate, rule: rule, value: new_value)]
    end

    def handle_predicate_false(rule, open_alert, candidate)
      transitions = []

      if candidate.present?
        transitions << transition(:cancel_candidate, rule: rule, candidate: candidate)
      end

      if open_alert.present?
        transitions << transition(:close_alert, rule: rule, alert: open_alert, value: new_value)
      end

      transitions
    end

    def transition(kind, rule:, alert: nil, candidate: nil, value: nil)
      Transition.new(
        kind:       kind,
        alert_rule: rule,
        alert:      alert,
        candidate:  candidate,
        value:      value,
        at:         at
      )
    end

    # ── Predicates ──────────────────────────────────────

    def predicate_true_for?(rule)
      case rule.condition_type
      when 'status_change'
        status_change_predicate?(rule)
      when 'threshold'
        threshold_predicate?(rule)
      else
        false
      end
    end

    # status_change is an *edge* event: a status_change rule's predicate
    # is "true" only on the reading that produced the transition. The
    # closer (next reading without the transition) flips it false again.
    # This means status_change alerts that have no dwell open and close
    # on consecutive readings, which is the expected semantics: each
    # transition produces one open + one close in the alert log.
    def status_change_predicate?(rule)
      old_bool = cast_boolean(old_value)
      new_bool = cast_boolean(new_value)

      if old_bool.nil? || new_bool.nil? || old_bool == new_bool
        return false
      end

      case rule.direction
      when 'to_on'
        new_bool == true
      when 'to_off'
        new_bool == false
      when 'both'
        true
      else
        false
      end
    end

    # threshold is a *level* predicate: the new scaled value crosses the
    # rule's threshold. Uses the MP's effective scaling so rule thresholds
    # are expressed in display units, not raw register units.
    def threshold_predicate?(rule)
      scaled = scale(new_value)
      if scaled.nil? || rule.threshold_value.nil?
        return false
      end

      case rule.direction
      when 'above'
        scaled > rule.threshold_value
      when 'below'
        scaled < rule.threshold_value
      else
        false
      end
    end

    def cast_boolean(value)
      if value.nil?
        return nil
      end

      ActiveModel::Type::Boolean.new.cast(value)
    end

    def scale(raw)
      if raw.nil?
        return nil
      end

      measurement_point.scale_decoded_value(raw)
    end
end
