class AlertCandidate < ApplicationRecord
  belongs_to :alert_rule

  has_one :measurement_point, through: :alert_rule

  validates :predicate_first_true_at, presence: true
  validates :alert_rule_id, uniqueness: true

  def dwell_elapsed?(at: Time.current)
    if !alert_rule.has_dwell?
      return true
    end

    (at - predicate_first_true_at) >= alert_rule.min_duration_seconds
  end

  def elapsed_seconds(at: Time.current)
    (at - predicate_first_true_at).to_i
  end
end
