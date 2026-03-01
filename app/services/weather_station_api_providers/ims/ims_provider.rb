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
      end

      # Fetch latest readings for a single station
      # Returns: Array of { metric_key:, value:, sample_time: (UTC) }
      def fetch_latest
        station_id = @weather_station_api_location.provider_config['station_id']

        if station_id.blank?
          raise ImsWeatherClient::Error, "No station_id configured for weather location #{@weather_station_api_location.id}"
        end

        response = @client.latest_data(station_id)
        parse_station_data(response)
      end

      # Fetch a full day of readings for a single station
      def fetch_daily(date)
        station_id = @weather_station_api_location.provider_config['station_id']

        if station_id.blank?
          raise ImsWeatherClient::Error, "No station_id configured for weather location #{@weather_station_api_location.id}"
        end

        response = @client.daily_data(station_id, date)
        parse_station_data(response)
      end

      # Fetch date range for a single station
      def fetch_range(from_date, to_date)
        station_id = @weather_station_api_location.provider_config['station_id']

        if station_id.blank?
          raise ImsWeatherClient::Error, "No station_id configured for weather location #{@weather_station_api_location.id}"
        end

        response = @client.range_data(station_id, from_date, to_date)
        parse_station_data(response)
      end

      # Fetch latest data for an entire region (all stations)
      # Returns: Hash of { station_id => [{ metric_key:, value:, sample_time: }] }
      def self.fetch_region_latest(region_id)
        client = ImsWeatherClient.new
        response = client.region_latest_data(region_id)
        parse_region_data(response)
      end

      # Fetch daily data for an entire region
      def self.fetch_region_daily(region_id, date)
        client = ImsWeatherClient.new
        response = client.region_daily_data(region_id, date)
        parse_region_data(response)
      end

      # Fetch date range for an entire region
      def self.fetch_region_range(region_id, from_date, to_date)
        client = ImsWeatherClient.new
        response = client.region_range_data(region_id, from_date, to_date)
        parse_region_data(response)
      end

      private
        def parse_station_data(response)
          self.class.parse_observations(response)
        end

        # Parse region response: returns { station_id => [readings] }
        # Region response is an array of station objects, each with stationId and data
        def self.parse_region_data(response)
          result = {}

          stations_data = if response.is_a?(Array)
            response
          elsif response.is_a?(Hash)
            response.fetch('data', response.fetch('stations', []))
          else
            Rails.logger.warn("[WeatherStationApiProviders::Ims] Unexpected region response format: #{response.class}")
            return result
          end

          stations_data.each do |station_data|
            station_id = station_data['stationId']

            if station_id.nil?
              next
            end

            observations = station_data['data'] || station_data['Data'] || []
            readings = parse_observations(observations)

            if readings.any?
              result[station_id.to_i] = readings
            end
          end

          result
        end

        # Parse an array of observation records into normalized readings
        def self.parse_observations(response)
          readings = []

          data = if response.is_a?(Hash)
            response.fetch('data', [])
          elsif response.is_a?(Array)
            response
          else
            Rails.logger.warn("[WeatherStationApiProviders::Ims] Unexpected data format: #{response.class}")
            return readings
          end

          if !data.is_a?(Array)
            Rails.logger.warn("[WeatherStationApiProviders::Ims] Expected array, got: #{data.class}")
            return readings
          end

          data.each do |observation|
            sample_time = parse_ims_datetime(observation['datetime'])

            if sample_time.nil?
              Rails.logger.warn("[WeatherStationApiProviders::Ims] Could not parse datetime: #{observation['datetime']}")
              next
            end

            channels = observation['channels'] || []

            channels.each do |channel|
              if !channel['valid']
                next
              end

              if channel['status'].present? && channel['status'] != 1
                next
              end

              channel_name = channel['name']
              metric_key = CHANNEL_MAP[channel_name]

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

        # IMS API docs: "The observation date is always in Israel winter time (UTC + 2),
        # and not as mentioned in the output datetime +03:00"
        def self.parse_ims_datetime(datetime_str)
          if datetime_str.blank?
            return nil
          end

          base_time = datetime_str.sub(/[+-]\d{2}:\d{2}$/, '')
          Time.parse("#{base_time}#{IMS_FIXED_UTC_OFFSET}").utc
        rescue ArgumentError => e
          Rails.logger.warn("[WeatherStationApiProviders::Ims] DateTime parse error: #{e.message} for '#{datetime_str}'")
          nil
        end
    end
  end
end
