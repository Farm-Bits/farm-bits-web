class WeatherStationApiLocationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:weather_station_api_location_sites)
        .where(weather_station_api_location_sites: { site_id: current_site.id })
        .distinct
    end
  end
end
