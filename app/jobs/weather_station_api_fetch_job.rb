class WeatherStationApiFetchJob
  include Sidekiq::Job
  queue_as :low
  sidekiq_options retry: 3

  def perform
    weather_station_api_locations = WeatherStationApiLocation.needs_fetch

    weather_station_api_locations.find_each.with_index do |weather_station_api_location, index|
      WeatherStationApiLocationFetchJob.perform_in(index * 6, weather_station_api_location.id)
    end
  end
end
