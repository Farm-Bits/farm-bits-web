class OnesignalDeliveryMethod
  include HTTParty

  ONESIGNAL_API_URL = 'https://api.onesignal.com/notifications'

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
      ONESIGNAL_API_URL,
      headers: {
        'Content-Type'  => 'application/json',
        'Authorization' => "Bearer #{Rails.application.credentials[:onesignal][:api_key]}"
      },
      body: payload.to_json
    )

    parsed = response.parsed_response
    errors = parsed['errors']

    if !response.success? || (errors && errors.any?)
      error_message = errors.is_a?(Array) ? errors.join(', ') : errors.to_s
      raise "OneSignal delivery failed (#{response.code}): #{error_message}"
    end
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
