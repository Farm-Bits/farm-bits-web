module WeatherStationApiProviders
  module Ims
    class ImsProvider
      # IMS API documentation states observation times are in Israel winter time (UTC+2),
      # regardless of what the response datetime offset says.
      IMS_TIMEZONE = 'Asia/Jerusalem'
      IMS_FIXED_UTC_OFFSET = '+02:00'

      # Map IMS channel variable codes to our weather_metric keys.
      # Channel IDs vary per station, but the variable codes (names) are consistent.
      CHANNEL_MAP = {
        'TD'     => 'temperature',
        # 'TDmax'  => 'temperature_max',
        # 'TDmin'  => 'temperature_min',
        'RH'     => 'humidity',
        'Rain'   => 'precipitation',
        'WS'     => 'wind_speed',
        # 'WSmax'  => 'wind_speed_gust',
        'WD'     => 'wind_direction',
        # 'WDmax'  => 'wind_direction_gust',
        'BP'     => 'barometric_pressure',
        'Grad'   => 'global_radiation',
        'NIP'    => 'direct_radiation',
        'DiffR'  => 'diffused_radiation',
        # 'TG'     => 'grass_min_temperature'
      }.freeze

      def initialize(weather_station_api_location)
        @weather_station_api_location = weather_station_api_location
        @client = ImsWeatherClient.new
        @metrics_cache = nil
      end

      # Fetch latest readings and return normalized data
      # Returns: Array of { metric_key:, value:, sample_time: (UTC) }
      def fetch_latest
        station_id = @weather_station_api_location.provider_config['station_id']

        if station_id.blank?
          raise ImsWeatherClient::Error, "No station_id configured for weather location #{@weather_station_api_location.id}"
        end

        response = @client.latest_data(station_id)
        parse_station_data(response)
      end

      # Fetch a full day of readings
      # Returns: Array of { metric_key:, value:, sample_time: (UTC) }
      def fetch_daily(date)
        station_id = @weather_station_api_location.provider_config['station_id']

        if station_id.blank?
          raise ImsWeatherClient::Error, "No station_id configured for weather location #{@weather_station_api_location.id}"
        end

        response = @client.daily_data(station_id, date)
        parse_station_data(response)
      end

      # Fetch date range
      def fetch_range(from_date, to_date)
        station_id = @weather_station_api_location.provider_config['station_id']

        if station_id.blank?
          raise ImsWeatherClient::Error, "No station_id configured for weather location #{@weather_station_api_location.id}"
        end

        response = @client.range_data(station_id, from_date, to_date)
        parse_station_data(response)
      end

      private
        def parse_station_data(response)
          readings = []

          data = response.is_a?(Hash) ? response.fetch('data', []) : response

          if !data.is_a?(Array)
            Rails.logger.warn("[WeatherProviders::Ims] Unexpected data format for location #{@weather_station_api_location.id}: #{data.class}")
            return readings
          end

          data.each do |observation|
            sample_time = parse_ims_datetime(observation['datetime'])

            if sample_time.nil?
              Rails.logger.warn("[WeatherProviders::Ims] Could not parse datetime for location #{@weather_station_api_location.id}: #{observation['datetime']}")
              next
            end

            channels = observation['channels'] || []

            channels.each do |channel|
              # Skip invalid readings
              if !channel['valid']
                next
              end

              if channel['status'].present? && channel['status'] != 1
                next
              end

              channel_name = channel['name']
              metric_key = CHANNEL_MAP[channel_name]

              # Skip channels we don't track
              if metric_key.nil?
                next
              end

              value = channel['value']

              if value.nil?
                next
              end

              readings << {
                metric_key: metric_key,
                value: value.to_d,
                sample_time: sample_time
              }
            end
          end

          readings
        end

        # IMS API docs state: "The observation date is always in Israel winter time (UTC + 2),
        # and not as mentioned in the output datetime +03:00"
        # So we parse the time portion and apply fixed UTC+2 offset, then convert to UTC.
        def parse_ims_datetime(datetime_str)
          if datetime_str.blank?
            return nil
          end

          # The API returns datetimes like "2024-01-15T14:30:00+02:00" or "2024-01-15T14:30:00+03:00"
          # Per docs, the actual offset is always UTC+2 regardless of what's shown.
          # Strip any existing offset and apply the fixed one.
          base_time = datetime_str.sub(/[+-]\d{2}:\d{2}$/, '')
          Time.parse("#{base_time}#{IMS_FIXED_UTC_OFFSET}").utc
        rescue ArgumentError => e
          Rails.logger.warn("[WeatherProviders::Ims] DateTime parse error for location #{@weather_station_api_location.id}: #{e.message} for '#{datetime_str}'")
          nil
        end
    end
  end
end
