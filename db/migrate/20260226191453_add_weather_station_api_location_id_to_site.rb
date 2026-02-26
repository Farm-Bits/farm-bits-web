class AddWeatherStationApiLocationIdToSite < ActiveRecord::Migration[7.2]
  def change
    add_reference :sites, :weather_station_api_location, foreign_key: { on_delete: :nullify }, after: :time_zone
  end
end
