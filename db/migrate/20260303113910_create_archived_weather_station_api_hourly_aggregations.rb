class CreateArchivedWeatherStationApiHourlyAggregations < ActiveRecord::Migration[7.2]
  def change
    create_table :archived_weather_station_api_hourly_aggregations do |t|
      t.references :weather_station_api_location, null: false, foreign_key: { on_delete: :cascade }
      t.references :weather_station_api_metric, null: false, foreign_key: { on_delete: :cascade }
      t.datetime :hour_timestamp, null: false
      t.decimal :min_value, precision: 15, scale: 4
      t.decimal :max_value, precision: 15, scale: 4
      t.decimal :avg_value, precision: 15, scale: 4
      t.decimal :sum_value, precision: 15, scale: 4
      t.integer :sample_count, null: false

      t.timestamps
    end

    add_index :archived_weather_station_api_hourly_aggregations, [:weather_station_api_location_id, :weather_station_api_metric_id, :hour_timestamp], unique: true
    add_index :archived_weather_station_api_hourly_aggregations, :hour_timestamp
  end
end
