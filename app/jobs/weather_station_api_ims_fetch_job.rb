class WeatherStationApiImsFetchJob
  include Sidekiq::Job
  sidekiq_options queue: 'default', retry: 3

  def perform
    locations = WeatherStationApiLocation.needs_fetch.where(provider: 'ims')
    locations_by_region = locations.group_by { |loc| loc.provider_config['region_id'].to_i }

    locations_by_region.each do |region_id, region_locations|
      locations_by_station_id = region_locations.index_by { |loc| loc.provider_config['station_id'].to_i }

      region_data = WeatherStationApiProviders::Ims::ImsProvider.fetch_region_latest(region_id)

      region_data.each do |station_id, readings|
        location = locations_by_station_id[station_id]

        if location.nil? || readings.blank?
          next
        end

        WeatherStationApiRecordingService.record(location, readings)
      end
    rescue WeatherStationApiProviders::Ims::ImsWeatherClient::Error => e
      Rails.logger.warn("[WeatherStationImsFetchJob] Region #{region_id} failed: #{e.message}")
    rescue => e
      Rails.logger.error("[WeatherStationImsFetchJob] Region #{region_id} unexpected error: #{e.class} - #{e.message}")
    end
  end
end
