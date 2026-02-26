class WeatherStationApiLocationFetchJob
  include Sidekiq::Job
  queue_as :low
  sidekiq_options retry: 3

  def perform(weather_station_api_location_id)
    weather_station_api_location = WeatherStationApiLocation.find_by(id: weather_station_api_location_id)

    if weather_station_api_location.nil?
      Rails.logger.warn("[WeatherStationApiLocationFetchJob] Weather Station API Location #{weather_station_api_location_id} not found, skipping")
      return
    end

    if !weather_station_api_location.active?
      Rails.logger.info("[WeatherStationApiLocationFetchJob] Weather Station API Location #{weather_station_api_location.id} is inactive, skipping")
      return
    end

    adapter = weather_station_api_location.provider_adapter
    readings = adapter.fetch_latest

    WeatherStationApiRecordingService.record(weather_station_api_location, readings)
  rescue WeatherStationApiProviders::Ims::ImsWeatherClient::RateLimitError => e
    Rails.logger.warn("[WeatherStationApiLocationFetchJob] Rate limited for Weather Station API Location #{weather_station_api_location_id}: #{e.message}")
    # Re-raise to trigger Sidekiq retry with backoff
    raise
  rescue WeatherStationApiProviders::Ims::ImsWeatherClient::Error => e
    Rails.logger.error("[WeatherStationApiLocationFetchJob] API error for Weather Station API Location #{weather_station_api_location_id}: #{e.message}")
    raise
  rescue => e
    Rails.logger.error("[WeatherStationApiLocationFetchJob] Unexpected error for Weather Station API location #{weather_station_api_location_id}: #{e.class} - #{e.message}")
    raise
  end
end
