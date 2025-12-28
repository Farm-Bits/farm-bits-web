class CreateMeasurementPoints < ActiveRecord::Migration[7.0]
  def change
    create_table :measurement_points do |t|
      t.string :name, null: false
      t.text :description

      t.string :unit_override
      t.string :chart_type_override
      t.string :color_override
      t.boolean :data_collection_enabled_override
      t.integer :polling_interval_seconds_override

      t.decimal :factor_override, precision: 15, scale: 10
      t.decimal :offset_override, precision: 15, scale: 6

      # Alarm thresholds
      t.decimal :alarm_low, precision: 15, scale: 6
      t.decimal :alarm_high, precision: 15, scale: 6
      t.decimal :warning_low, precision: 15, scale: 6
      t.decimal :warning_high, precision: 15, scale: 6

      # Current value cache (updated on each reading)
      t.decimal :current_value, precision: 15, scale: 6
      t.datetime :current_value_at

      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.references :plc, null: false, foreign_key: { on_delete: :cascade }
      t.references :register_template, null: false, foreign_key: { on_delete: :cascade }
      t.references :client, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :measurement_points, [:plc_id, :register_template_id], unique: true
    add_index :measurement_points, :active
    add_index :measurement_points, :data_collection_enabled_override
    add_index :measurement_points, [:plc_id, :data_collection_enabled_override]
    add_index :measurement_points, [:plc_id, :position]
  end
end
