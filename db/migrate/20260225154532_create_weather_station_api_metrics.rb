class CreateWeatherStationApiMetrics < ActiveRecord::Migration[7.2]
  def change
    create_table :weather_station_api_metrics do |t|
      t.string :key, null: false
      t.string :label, null: false
      t.string :unit, null: false
      t.decimal :factor, null: false, precision: 15, scale: 6, default: 1.0
      t.decimal :offset, null: false, precision: 15, scale: 6, default: 0.0
      t.string :aggregation, null: false
      t.references :measurement_subtype, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :weather_station_api_metrics, :key, unique: true
  end
end
