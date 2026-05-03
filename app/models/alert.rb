class Alert < ApplicationRecord
  audited

  belongs_to :alert_rule,        optional: true
  belongs_to :measurement_point, optional: true
  belongs_to :site,              optional: true

  validates :rule_name,              presence: true
  validates :severity,               presence: true, inclusion: { in: AlertRule::SEVERITIES }
  validates :condition_type,         presence: true, inclusion: { in: AlertRule::CONDITION_TYPES }
  validates :measurement_point_name, presence: true
  validates :segment_name,           presence: true
  validates :started_at,             presence: true
  validate  :ended_at_after_started_at

  scope :open,   -> { where(ended_at: nil) }
  scope :closed, -> { where.not(ended_at: nil) }
  scope :ordered, -> { order(started_at: :desc) }

  # Builds an Alert with all snapshot fields populated from the rule and
  # its current measurement point. The caller is responsible for setting
  # started_value and saving.
  #
  # @return [Alert] unsaved
  def self.build_from_rule(alert_rule, started_at: Time.current)
    mp   = alert_rule.measurement_point
    site = mp&.site

    new(
      alert_rule:             alert_rule,
      measurement_point:      mp,
      site:                   site,
      rule_name:              alert_rule.name,
      severity:               alert_rule.severity,
      condition_type:         alert_rule.condition_type,
      direction:              alert_rule.direction,
      threshold_value:        alert_rule.threshold_value,
      inactivity_seconds:     alert_rule.inactivity_seconds,
      min_duration_seconds:   alert_rule.min_duration_seconds,
      measurement_point_name: mp&.name.to_s,
      segment_name:           mp&.segment&.name.to_s,
      unit:                   mp&.effective_unit,
      started_at:             started_at
    )
  end

  def open?
    ended_at.nil?
  end

  def closed?
    !open?
  end

  def severity_level
    AlertRule::SEVERITIES.index(severity)
  end

  # Total time the alert was (or has been) open, in seconds.
  def duration_seconds
    ((ended_at || Time.current) - started_at).to_i
  end

  # Snapshot is the source of truth for display; live FKs may be nil.
  def display_threshold
    threshold_value
  end

  private
    def ended_at_after_started_at
      if ended_at.blank? || started_at.blank?
        return
      end

      if ended_at < started_at
        errors.add(:ended_at, 'must be on or after started_at')
      end
    end
end
