class CreateWeatherStationApiLocations < ActiveRecord::Migration[7.2]
  def change
    create_table :weather_station_api_locations do |t|
      t.string :name, null: false
      t.decimal :latitude, null: false, precision: 10, scale: 7
      t.decimal :longitude, null: false, precision: 10, scale: 7
      t.string :provider, null: false
      t.json :provider_config
      t.string :time_zone, null: false
      t.boolean :active, null: false, default: true
      t.datetime :last_fetched_at
      t.integer :fetch_interval_minutes, null: false

      t.timestamps
    end

    add_index :weather_station_api_locations, [:latitude, :longitude]
    add_index :weather_station_api_locations, :provider
  end
end
