class CreateWeatherStationApiHourlyAggregations < ActiveRecord::Migration[7.2]
  def change
    create_table :weather_station_api_hourly_aggregations do |t|
      t.references :weather_station_api_location, null: false, foreign_key: { on_delete: :cascade }
      t.references :weather_station_api_metric, null: false, foreign_key: { on_delete: :cascade }
      t.date :date, null: false
      t.integer :hour, null: false
      t.decimal :min_value, precision: 15, scale: 4
      t.decimal :max_value, precision: 15, scale: 4
      t.decimal :avg_value, precision: 15, scale: 4
      t.decimal :sum_value, precision: 15, scale: 4
      t.integer :sample_count, null: false

      t.timestamps
    end

    add_index :weather_station_api_hourly_aggregations, [:weather_station_api_location_id, :weather_station_api_metric_id, :hour], unique: true
    add_index :weather_station_api_hourly_aggregations, :hour
  end
end
