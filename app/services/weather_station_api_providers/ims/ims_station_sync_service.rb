module WeatherStationApiProviders
  module Ims
    class ImsStationSyncService
      # Fetches all IMS stations and creates/updates WeatherLocation records.
      # Useful for initial setup and periodic station list refresh.
      #
      # Usage:
      #   WeatherStationApiProviders::Ims::ImsStationSyncService.sync_all          # Import all ~85 stations
      #   WeatherStationApiProviders::Ims::ImsStationSyncService.sync_station(28)  # Import specific station
      #   WeatherStationApiProviders::Ims::ImsStationSyncService.list_stations     # List available stations (for console)

      def self.list_stations
        client = ImsWeatherClient.new
        stations = client.stations

        stations.each do |station|
          location = station['location'] || {}
          monitors = station['monitors'] || []
          active_channels = monitors.select { |m| m['active'] }.map { |m| m['name'] }

          puts "Station #{station['stationId']}: #{station['name']}"
          puts "  Location: #{location['latitude']}, #{location['longitude']}"
          puts "  Region: #{station['regionId']}"
          puts "  Channels: #{active_channels.join(', ')}"
          puts ""
        end

        stations.size
      end

      def self.sync_all
        client = ImsWeatherClient.new
        stations = client.stations

        created = 0
        updated = 0
        skipped = 0

        stations.each do |station_data|
          result = sync_station_data(station_data)
          case result
          when :created then created += 1
          when :updated then updated += 1
          when :skipped then skipped += 1
          end
        end

        Rails.logger.info(
          "[ImsStationSyncService] Sync complete: #{created} created, #{updated} updated, #{skipped} skipped"
        )

        { created: created, updated: updated, skipped: skipped }
      end

      def self.sync_station(station_id)
        client = ImsWeatherClient.new
        station_data = client.station(station_id)
        sync_station_data(station_data)
      end

      private
        def self.sync_station_data(station_data)
          station_id = station_data['stationId']
          location = station_data['location'] || {}
          latitude = location['latitude']
          longitude = location['longitude']

          if latitude.blank? || longitude.blank?
            Rails.logger.warn("[ImsStationSyncService] Station #{station_id} has no coordinates, skipping")
            return :skipped
          end

          monitors = station_data['monitors'] || []
          active_channels = monitors.select { |m| m['active'] }.map { |m| m['name'] }

          weather_station_api_location = WeatherStationApiLocation.where(provider: 'ims')
            .where("JSON_EXTRACT(provider_config, '$.station_id') = ?", station_id)
            .first

          attributes = {
            name: "IMS: #{station_data['name']}",
            latitude: latitude,
            longitude: longitude,
            provider: 'ims',
            provider_config: {
              station_id: station_id,
              station_name: station_data['name'],
              region_id: station_data['regionId'],
              active_channels: active_channels
            },
            time_zone: 'Asia/Jerusalem',
            active: true,
            fetch_interval_minutes: 10
          }

          if weather_station_api_location.nil?
            WeatherStationApiLocation.create!(attributes)
            Rails.logger.info("[ImsStationSyncService] Created location for IMS station #{station_id}: #{station_data['name']}")
            :created
          else
            weather_station_api_location.update!(attributes.except(:provider, :provider_config).merge(
              provider_config: weather_station_api_location.provider_config.merge(
                'active_channels' => active_channels,
                'region_id' => station_data['regionId']
              )
            ))
            Rails.logger.info("[ImsStationSyncService] Updated location for IMS station #{station_id}: #{station_data['name']}")
            :updated
          end
        rescue => e
          Rails.logger.error("[ImsStationSyncService] Error syncing station #{station_data&.dig('stationId')}: #{e.message}")
          :skipped
        end
    end
  end
end
