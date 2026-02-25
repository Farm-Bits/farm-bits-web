class CreateWeatherStationApiLocationSites < ActiveRecord::Migration[7.2]
  def change
    create_table :weather_station_api_location_sites do |t|
      t.references :weather_station_api_location, null: false, foreign_key: { on_delete: :cascade }
      t.references :site, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :weather_station_api_location_sites, [:weather_station_api_location_id, :site_id], unique: true
  end
end
