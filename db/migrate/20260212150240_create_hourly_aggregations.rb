class CreateHourlyAggregations < ActiveRecord::Migration[7.2]
  def change
    create_table :hourly_aggregations do |t|
      t.date :date, null: false
      t.integer :hour, null: false
      t.string :value_type, null: false

      # Shared
      t.integer :reading_count, null: false, default: 0

      # Accumulative (counter) fields
      t.decimal :start_value, precision: 20, scale: 6
      t.decimal :end_value, precision: 20, scale: 6
      t.decimal :delta, precision: 20, scale: 6

      # Instantaneous fields
      t.decimal :min_value, precision: 20, scale: 6
      t.decimal :max_value, precision: 20, scale: 6
      t.decimal :avg_value, precision: 20, scale: 6
      t.decimal :sum_value, precision: 20, scale: 6

      # Status fields
      t.integer :time_on_seconds
      t.integer :time_off_seconds
      t.integer :transition_count

      t.datetime :first_reading_at
      t.datetime :last_reading_at
      t.references :measurement_point, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :hourly_aggregations, [:measurement_point_id, :date, :hour], unique: true
    add_index :hourly_aggregations, [:measurement_point_id, :date]
    add_index :hourly_aggregations, :date
  end
end
