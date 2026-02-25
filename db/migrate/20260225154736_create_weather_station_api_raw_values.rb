class CreateWeatherStationApiRawValues < ActiveRecord::Migration[7.2]
  def change
    create_table :weather_station_api_raw_values do |t|
      t.references :weather_station_api_location, null: false, foreign_key: { on_delete: :cascade }
      t.references :weather_station_api_metric, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :value, null: false, precision: 15, scale: 4
      t.decimal :scaled_value, null: false, precision: 15, scale: 4
      t.datetime :sample_time, null: false

      t.datetime :created_at, null: false
    end

    add_index :weather_station_api_raw_values, [:weather_station_api_location_id, :weather_station_api_metric_id, :sample_time], unique: true
    add_index :weather_station_api_raw_values, :sample_time
  end
end
