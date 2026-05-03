class AlertRule < ApplicationRecord
  audited

  belongs_to :measurement_point

  has_one :site, through: :measurement_point
  has_one :alert_candidate, dependent: :destroy
  has_many :alerts, dependent: :nullify

  SEVERITIES      = %w[info warning critical].freeze
  CONDITION_TYPES = %w[status_change threshold inactivity].freeze
  STATUS_CHANGE_DIRECTIONS = %w[to_on to_off both].freeze
  THRESHOLD_DIRECTIONS     = %w[above below].freeze

  validates :name, presence: true
  validates :severity,       inclusion: { in: SEVERITIES }
  validates :condition_type, inclusion: { in: CONDITION_TYPES }
  validates :direction, inclusion: { in: STATUS_CHANGE_DIRECTIONS }, if: :status_change?
  validates :direction, inclusion: { in: THRESHOLD_DIRECTIONS },     if: :threshold?
  validates :direction, absence: true, if: :inactivity?
  validates :threshold_value, presence: true, if: :threshold?
  validates :threshold_value, absence: true,  if: -> { status_change? || inactivity? }
  validates :inactivity_seconds,
    presence: true,
    numericality: { only_integer: true, greater_than: 0 },
    if: :inactivity?
  validates :inactivity_seconds, absence: true, if: -> { status_change? || threshold? }
  validates :min_duration_seconds,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 },
    allow_nil: true
  validates :min_duration_seconds, absence: true, if: :status_change_with_dwell?
  validate :measurement_point_compatible_with_condition_type

  before_save :reset_candidate_if_predicate_definition_changed

  scope :active, -> { where(active: true) }
  scope :status_change, -> { where(condition_type: 'status_change') }
  scope :threshold,     -> { where(condition_type: 'threshold') }
  scope :inactivity,    -> { where(condition_type: 'inactivity') }

  def status_change?
    condition_type == 'status_change'
  end

  def threshold?
    condition_type == 'threshold'
  end

  def inactivity?
    condition_type == 'inactivity'
  end

  def has_dwell?
    min_duration_seconds.to_i > 0
  end

  def severity_level
    SEVERITIES.index(severity)
  end

  private
    def status_change_with_dwell?
      status_change? && min_duration_seconds.to_i > 0
    end

    # status_change rules need a status-category MP. threshold rules need a
    # numeric register. inactivity works against anything that gets polled.
    def measurement_point_compatible_with_condition_type
      if !measurement_point.present? || !measurement_point.register_template.present?
        return
      end

      rt = measurement_point.register_template

      if status_change? && rt.value_format != 'boolean'
        errors.add(:condition_type, "status_change requires a boolean register, got '#{rt.value_format}'")
      end

      if threshold? && !rt.numeric_register?
        errors.add(:condition_type, "threshold requires a numeric register, got '#{rt.value_format}'")
      end
    end

    # If anything that defines what "predicate true" means changes, the
    # current dwell candidate (if any) is no longer valid - drop it so the
    # next evaluation starts fresh.
    def reset_candidate_if_predicate_definition_changed
      if new_record?
        return
      end

      relevant = %w[
        condition_type direction threshold_value
        inactivity_seconds min_duration_seconds active
        measurement_point_id
      ]
      if (changes.keys & relevant).empty?
        return
      end

      AlertCandidate.where(alert_rule_id: id).delete_all
    end
end
