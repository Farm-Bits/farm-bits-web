# Sends push notifications via OneSignal. Independent of the email
# delivery method (which uses ActionMailer), because OneSignal's push
# payload is structurally different from its email payload.
#
# Targets users by their OneSignal external_user_id, which we set to
# User#id.to_s when devices register. Until the mobile app exists,
# every send is a no-op from the user's perspective (no devices
# registered = OneSignal accepts the request and delivers to nobody),
# which is the correct degraded behavior.
#
class OnesignalPushClient
  include HTTParty

  ONESIGNAL_API_URL = 'https://api.onesignal.com/notifications'

  class Error < StandardError; end

  def self.send_push!(user_id:, title:, body:, data: {})
    new.send_push!(user_id: user_id, title: title, body: body, data: data)
  end

  def send_push!(user_id:, title:, body:, data: {})
    payload = {
      app_id:                   credential(:app_id),
      include_external_user_ids: [user_id.to_s],
      channel_for_external_user_ids: 'push',
      headings:                 { en: title },
      contents:                 { en: body },
      data:                     data
    }

    response = self.class.post(
      ONESIGNAL_API_URL,
      headers: {
        'Content-Type'  => 'application/json',
        'Authorization' => "Bearer #{credential(:api_key)}"
      },
      body: payload.to_json,
      timeout: 10
    )

    parsed = response.parsed_response
    errors = parsed.is_a?(Hash) ? parsed['errors'] : nil

    if response.success? && (errors.nil? || errors.empty?)
      return true
    end

    error_message = errors.is_a?(Array) ? errors.join(', ') : errors.to_s
    Bugsnag.notify("OneSignal push delivery failed: #{error_message}") do |report|
      report.severity = 'warning'
      report.add_metadata(:push, { user_id: user_id, response: parsed })
    end

    false
  rescue HTTParty::Error, Net::OpenTimeout, Net::ReadTimeout, SocketError => e
    Rails.logger.warn("OnesignalPushClient transport error: #{e.class} - #{e.message}")
    Bugsnag.notify(e) { |r| r.severity = 'warning' }
    false
  end

  private
    def credential(key)
      Rails.application.credentials[:onesignal][key]
    end
end
