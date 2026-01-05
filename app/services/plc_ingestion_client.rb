class PlcIngestionClient
  class Error < StandardError
  end

  class AuthenticationError < Error
  end

  class NotFoundError < Error
  end

  BASE_URL = Rails.application.credentials[:plc_ingestion][:base_url]
  TOKEN = Rails.application.credentials[:plc_ingestion][:webhook_token]

  class << self
    def authorize_email(email, active: true)
      response = HTTParty.post(
        "#{BASE_URL}/api/v1/authorized_emails",
        headers: {
          'Authorization' => "Bearer #{TOKEN}",
          'Content-Type' => 'application/json'
        },
        body: {
          authorized_email: {
            email: email,
            active: active
          }
        }.to_json
      )

      handle_response(response)
    end

    def update_email(email, active:)
      response = HTTParty.patch(
        "#{BASE_URL}/api/v1/authorized_emails/#{CGI.escape(email)}",
        headers: {
          'Authorization' => "Bearer #{TOKEN}",
          'Content-Type' => 'application/json'
        },
        body: {
          authorized_email: {
            active: active
          }
        }.to_json
      )

      handle_response(response)
    end

    def revoke_email(email)
      response = HTTParty.delete(
        "#{BASE_URL}/api/v1/authorized_emails/#{CGI.escape(email)}",
        headers: {
          'Authorization' => "Bearer #{TOKEN}",
          'Content-Type' => 'application/json'
        }
      )

      handle_response(response)
    end

    private
      def handle_response(response)
        case response.code
        when 200, 201
          response.parsed_response
        when 401, 403
          raise AuthenticationError, "Authentication failed: #{response.body}"
        when 404
          raise NotFoundError, "Resource not found: #{response.body}"
        when 422
          raise Error, "Validation failed: #{response.parsed_response['errors']&.join(', ')}"
        else
          raise Error, "Request failed with status #{response.code}: #{response.body}"
        end
      end
  end
end
