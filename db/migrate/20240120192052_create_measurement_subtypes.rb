class CreateMeasurementSubtypes < ActiveRecord::Migration[7.0]
  def change
    create_table :measurement_subtypes do |t|
      t.string :name, null: false
      t.string :value_type, null: false
      t.string :default_unit, null: false
      t.string :default_chart_type, null: false
      t.string :default_color

      # Aggregation configuration stored as JSON
      # Example for instantaneous:
      # {
      #   "fields": ["min_value", "max_value", "avg_value"],
      #   "hourly": { "min": "MIN(min_value)", "max": "MAX(max_value)", "avg": "AVG(avg_value)" },
      #   "daily": { "min": "MIN(min_value)", "max": "MAX(max_value)", "avg": "AVG(avg_value)" }
      # }
      t.jsonb :aggregation_config, default: {}

      t.integer :position, null: false, default: 0
      t.references :measurement_type, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :measurement_subtypes, [:measurement_type_id, :name], unique: true
    add_index :measurement_subtypes, [:measurement_type_id, :position]
    add_index :measurement_subtypes, :value_type
  end
end
