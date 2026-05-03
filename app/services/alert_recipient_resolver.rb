# Given a fired Alert, resolves the deduplicated set of (user, channels)
# pairs that should receive notifications.
#
# Cascade rules:
#   - The alert's MP cascades up through Plc → Site → Company.
#   - The alert's rule is also a valid scope anchor.
#   - Subscriptions matching ANY of those scopes are candidates.
#   - Severity floor and active flag filter further.
#   - When a user has multiple matching subscriptions (e.g. one at
#     Company and one at Site), their channels are unioned, then dedup.
#
# Returns: [{ user: User, channels: ['email', 'push'] }, ...]
#
class AlertRecipientResolver
  def self.call(alert)
    new(alert).call
  end

  def initialize(alert)
    @alert = alert
  end

  def call
    scope_pairs = candidate_scopes
    if scope_pairs.empty?
      return []
    end

    subs = matching_subscriptions(scope_pairs)
    if subs.empty?
      return []
    end

    group_by_user(subs)
  end

  private
    attr_reader :alert

    # Build the [(scope_type, scope_id), ...] tuples the alert matches.
    # Uses live FKs where available; nil-survival is intentional - if the
    # rule was deleted, rule-anchored subscriptions just won't resolve.
    def candidate_scopes
      mp = alert.measurement_point
      pairs = []

      if alert.alert_rule_id.present?
        pairs << ['AlertRule', alert.alert_rule_id]
      end

      if mp.present?
        pairs << ['MeasurementPoint', mp.id]

        if mp.plc_id.present?
          pairs << ['Plc', mp.plc_id]
        end

        if mp.site_id.present?
          pairs << ['Site', mp.site_id]

          company_id = mp.site&.company_id
          if company_id.present?
            pairs << ['Company', company_id]
          end
        end
      end

      pairs
    end

    # Single query: all active subs whose (scope_type, scope_id) is in
    # the candidate set, with severity floor met.
    def matching_subscriptions(scope_pairs)
      conditions = scope_pairs.map { '(scope_type = ? AND scope_id = ?)' }.join(' OR ')
      bindings   = scope_pairs.flat_map { |t, i| [t, i] }

      AlertSubscription
        .active
        .where(conditions, *bindings)
        .where(min_severity: severities_at_or_below(alert.severity))
        .includes(:user)
        .to_a
    end

    # ['info', 'warning'] for alert.severity == 'warning', etc.
    def severities_at_or_below(alert_severity)
      level = AlertRule::SEVERITIES.index(alert_severity)
      AlertRule::SEVERITIES.first(level + 1)
    end

    # Group subs by user, union channels, drop inactive users.
    def group_by_user(subs)
      by_user = subs.group_by(&:user_id)

      by_user.filter_map do |_, user_subs|
        user = user_subs.first.user
        if !user&.active
          next
        end

        channels = user_subs.flat_map(&:channel_list).uniq
        if channels.empty?
          next
        end

        { user: user, channels: channels }
      end
    end
end
