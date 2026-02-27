module WeatherStationApiProviders
  module Ims
    class ImsWeatherClient
      include HTTParty
      base_uri 'https://api.ims.gov.il/v1/envista'

      class Error < StandardError; end
      class AuthenticationError < Error; end
      class RateLimitError < Error; end
      class NotFoundError < Error; end

      def initialize
        @api_token = Rails.application.credentials[:ims][:api_token]

        if @api_token.blank?
          raise Error, "IMS API token not configured in credentials"
        end
      end

      # Fetch all stations metadata
      # Returns array of station hashes with: stationId, name, location, monitors
      def stations
        response = get('/stations')
        response.parsed_response
      end

      # Fetch single station metadata
      def station(station_id)
        response = get("/stations/#{station_id}")
        response.parsed_response
      end

      # Fetch latest data for a station (all channels)
      def latest_data(station_id)
        response = get("/stations/#{station_id}/data/latest")
        response.parsed_response
      end

      # Fetch data for a specific date (all channels)
      # date: Date object
      def daily_data(station_id, date)
        formatted = date.strftime('%Y/%m/%d')
        response = get("/stations/#{station_id}/data/daily/#{formatted}")
        response.parsed_response
      end

      # Fetch data for a date range (all channels)
      # from_date, to_date: Date objects
      def range_data(station_id, from_date, to_date)
        formatted_from = from_date.strftime('%Y/%m/%d')
        formatted_to = to_date.strftime('%Y/%m/%d')
        response = get("/stations/#{station_id}/data", query: { from: formatted_from, to: formatted_to })
        response.parsed_response
      end

      # Fetch data for current day (all channels)
      def today_data(station_id)
        response = get("/stations/#{station_id}/data/daily")
        response.parsed_response
      end

      private
        def get(path, options = {})
          response = self.class.get(
            path,
            options.merge(
              headers: {
                'Authorization' => "ApiToken #{@api_token}",
                'Accept' => 'application/json'
              },
              open_timeout: 10,
              read_timeout: 30
            )
          )

          handle_response(response)
        end

        def handle_response(response)
          content_type = response.headers['content-type']&.downcase || ''

          if !content_type.include?('application/json')
            raise Error, "IMS API returned non-JSON response (#{content_type.truncate(50)}), likely maintenance page"
          end

          case response.code
          when 200
            response
          when 401, 403
            raise AuthenticationError, "IMS API authentication failed (HTTP #{response.code})"
          when 404
            raise NotFoundError, "IMS API resource not found (HTTP #{response.code})"
          when 429
            raise RateLimitError, "IMS API rate limit exceeded"
          else
            raise Error, "IMS API error: HTTP #{response.code} - #{response.body&.truncate(200)}"
          end
        end
    end
  end
end
