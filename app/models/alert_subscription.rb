class AlertSubscription < ApplicationRecord
  audited

  belongs_to :scope, polymorphic: true
  belongs_to :user

  CHANNELS         = %w[email push].freeze
  ALLOWED_SCOPE_TYPES = %w[Company Site Plc MeasurementPoint AlertRule].freeze

  validates :scope_type, inclusion: { in: ALLOWED_SCOPE_TYPES }
  validates :min_severity, inclusion: { in: AlertRule::SEVERITIES }
  validates :user_id, uniqueness: { scope: [:scope_type, :scope_id] }
  validate  :channels_format
  validate  :channels_present

  scope :active, -> { where(active: true) }

  def channel_list
    Array(channels).map(&:to_s)
  end

  def email?
    channel_list.include?('email')
  end

  def push?
    channel_list.include?('push')
  end

  def severity_level
    AlertRule::SEVERITIES.index(min_severity)
  end

  # True when this subscription should receive an alert of the given
  # severity. info(0) <= warning(1) <= critical(2).
  def covers_severity?(alert_severity)
    alert_level = AlertRule::SEVERITIES.index(alert_severity)
    if alert_level.nil?
      return false
    end

    severity_level <= alert_level
  end

  private
    def channels_format
      if !channels.is_a?(Array)
        errors.add(:channels, 'must be an array')
        return
      end

      invalid = channel_list - CHANNELS
      if invalid.any?
        errors.add(:channels, "contains unknown channels: #{invalid.join(', ')}")
      end
    end

    def channels_present
      if channels.is_a?(Array) && channel_list.empty?
        errors.add(:channels, 'must include at least one channel')
      end
    end
end
