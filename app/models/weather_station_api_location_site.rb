class WeatherStationApiLocationSite < ApplicationRecord
  audited

  belongs_to :weather_station_api_location
  belongs_to :site

  validates :weather_location_id, uniqueness: { scope: :site_id, message: 'is already linked to this site' }
end
