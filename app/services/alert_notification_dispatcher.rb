# Given a fired or cleared alert, resolves its recipients and fans out
# per-channel deliveries (email via AlertMailer, push via
# OnesignalPushClient).
#
# Channel failures are isolated - a failed push does not block the
# email, and vice versa. Per-recipient failures don't block other
# recipients. Everything goes to Bugsnag with context so we can audit
# delivery in production without halting the dispatch.
#
class AlertNotificationDispatcher
  LIFECYCLE_EVENTS = %w[opened closed].freeze

  def self.call(alert, lifecycle:)
    new(alert, lifecycle).call
  end

  def initialize(alert, lifecycle)
    @alert     = alert
    @lifecycle = lifecycle.to_s
  end

  def call
    if !LIFECYCLE_EVENTS.include?(@lifecycle)
      Rails.logger.error("AlertNotificationDispatcher: unknown lifecycle '#{@lifecycle}'")
      return
    end

    recipients = AlertRecipientResolver.call(@alert)
    if recipients.empty?
      return
    end

    recipients.each do |recipient|
      deliver_to(recipient[:user], recipient[:channels])
    end
  end

  private
    def deliver_to(user, channels)
      if channels.include?('email')
        deliver_email(user)
      end

      if channels.include?('push')
        deliver_push(user)
      end
    end

    def deliver_email(user)
      mailer_method = @lifecycle == 'opened' ? :alert_opened : :alert_closed
      AlertMailer.public_send(mailer_method, @alert.id, user.id).deliver_later
    rescue => e
      Rails.logger.error(
        "AlertNotificationDispatcher email failed: alert=#{@alert.id} user=#{user.id} - #{e.class}: #{e.message}"
      )
      Bugsnag.notify(e) do |report|
        report.severity = 'warning'
        report.add_metadata(:alert_dispatch, channel_metadata(user, 'email'))
      end
    end

    def deliver_push(user)
      OnesignalPushClient.send_push!(
        user_id: user.id,
        title:   push_title,
        body:    push_body,
        data:    {
          alert_id:  @alert.id,
          lifecycle: @lifecycle,
          severity:  @alert.severity
        }
      )
    rescue => e
      Rails.logger.error(
        "AlertNotificationDispatcher push failed: alert=#{@alert.id} user=#{user.id} - #{e.class}: #{e.message}"
      )
      Bugsnag.notify(e) do |report|
        report.severity = 'warning'
        report.add_metadata(:alert_dispatch, channel_metadata(user, 'push'))
      end
    end

    def push_title
      severity_label = @alert.severity.upcase
      verb           = @lifecycle == 'opened' ? 'fired' : 'cleared'
      "[#{severity_label}] #{verb.capitalize}: #{@alert.measurement_point_name}"
    end

    def push_body
      case @lifecycle
      when 'opened'
        "#{@alert.rule_name} — #{@alert.segment_name}"
      when 'closed'
        "Cleared after #{format_duration(@alert.duration_seconds)} — #{@alert.segment_name}"
      end
    end

    def format_duration(seconds)
      seconds = seconds.to_i

      if seconds < 60
        return "#{seconds}s"
      end

      if seconds < 3600
        return "#{seconds / 60}m"
      end

      "#{seconds / 3600}h"
    end

    def channel_metadata(user, channel)
      {
        alert_id:  @alert.id,
        user_id:   user.id,
        channel:   channel,
        lifecycle: @lifecycle,
        severity:  @alert.severity
      }
    end
end
