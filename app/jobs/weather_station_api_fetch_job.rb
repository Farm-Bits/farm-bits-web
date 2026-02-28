class WeatherStationApiFetchJob
  include Sidekiq::Job
  queue_as :low
  sidekiq_options retry: 3

  # Periodic job: discovers active weather station API locations that need fetching
  # and enqueues individual fetch jobs for each.
  def perform
    weather_station_api_locations = WeatherStationApiLocation.needs_fetch

    weather_station_api_locations.find_each.with_index do |weather_station_api_location, index|
      WeatherStationApiLocationFetchJob.perform_in(index * 4, weather_station_api_location.id)
    end
  end
end
