class PlcIngestionClient
  class Error < StandardError
  end

  class AuthenticationError < Error
  end

  class NotFoundError < Error
  end

  class ValidationError < Error
  end

  class ConnectionError < Error
  end

  BASE_URL = ENV['PLC_INGESTION_BASE_URL']
  TOKEN = ENV['PLC_INGESTION_SERVICE_API_KEY']

  class << self
    def create_authorized_email(plc)
      payload = {
        authorized_email: {
          email: plc.username,
          password: plc.password,
          active: plc.active
        }
      }
      response = HTTParty.post(
        "#{BASE_URL}/api/v1/authorized_emails",
        headers: {
          'Authorization' => "Bearer #{TOKEN}",
          'Content-Type' => 'application/json'
        },
        body: payload.to_json
      )

      handle_response(response)
    end

    def update_authorized_email(plc, previous_username, password_changed)
      if previous_username.present? && previous_username != plc.username
        delete_authorized_email(previous_username)
        create_authorized_email(plc)
      else
        payload = {
          authorized_email: {
            email: plc.username,
            active: plc.active
          }
        }
        if password_changed
          payload[:authorized_email][:password] = plc.password
        end
        response = HTTParty.put(
          "#{BASE_URL}/api/v1/authorized_emails/#{CGI.escape(plc.username)}",
          headers: {
            'Authorization' => "Bearer #{TOKEN}",
            'Content-Type' => 'application/json'
          },
          body: payload.to_json
        )
        handle_response(response)
      end
    end

    def delete_authorized_email(email)
      response = HTTParty.delete(
        "#{BASE_URL}/api/v1/authorized_emails/#{CGI.escape(email)}",
        headers: {
          'Authorization' => "Bearer #{TOKEN}",
          'Content-Type' => 'application/json'
        }
      )

      if response.code == 404
        return
      end

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
          raise ValidationError, "Validation failed: #{response.parsed_response['errors']&.join(', ')}"
        else
          raise ConnectionError, "Request failed with status #{response.code}: #{response.body}"
        end
      end
  end
end
