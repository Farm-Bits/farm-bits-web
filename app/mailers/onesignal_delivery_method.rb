class OnesignalDeliveryMethod
  include HTTParty

  base_uri 'https://api.onesignal.com'
  default_timeout 10
  open_timeout 5

  class DeliveryError < StandardError; end

  attr_accessor :settings

  def initialize(settings)
    @settings = settings
  end

  def deliver!(mail)
    payload = {
      app_id:               Rails.application.credentials[:onesignal][:app_id],
      email_subject:        mail.subject,
      email_body:           extract_html_body(mail),
      include_email_tokens: [mail.to.first],
      include_unsubscribed: true
    }

    response = self.class.post(
      '/notifications',
      headers: {
        'Content-Type'  => 'application/json',
        'Authorization' => "Bearer #{Rails.application.credentials[:onesignal][:api_key]}"
      },
      body: payload.to_json
    )

    parsed = response.parsed_response
    errors = parsed['errors']

    if !response.success? || (errors.present?)
      message = errors.is_a?(Array) ? errors.join(', ') : errors.to_s
      message = message.presence || "HTTP #{response.code}"
      Rails.logger.error("[OneSignal] delivery failed for #{mail.to.first}: #{message}")
      raise DeliveryError, "OneSignal delivery failed: #{message}"
    end

    parsed
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, HTTParty::Error => e
    Rails.logger.error("[OneSignal] network error for #{mail.to.first}: #{e.class} - #{e.message}")
    raise DeliveryError, "OneSignal network error: #{e.message}"
  end

  private
    def extract_html_body(mail)
      if mail.multipart?
        html_part = mail.html_part
        html_part ? html_part.body.decoded : mail.body.decoded
      elsif mail.content_type&.include?('text/html')
        mail.body.decoded
      else
        "<pre>#{mail.body.decoded}</pre>"
      end
    end
end
