class CreateAlerts < ActiveRecord::Migration[7.2]
  def change
    create_table :alerts do |t|
      t.string :rule_name, null: false
      t.string :severity, null: false
      t.string :condition_type, null: false
      t.string :direction
      t.decimal :threshold_value, precision: 15, scale: 6
      t.integer :inactivity_seconds
      t.integer :min_duration_seconds
      t.string :measurement_point_name, null: false
      t.string :unit
      t.string :segment_name, null: false
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.string :started_value
      t.string :ended_value
      t.references :measurement_point, foreign_key: { on_delete: :nullify }
      t.references :alert_rule, foreign_key: { on_delete: :nullify }
      t.references :site, foreign_key: { on_delete: :nullify }

      t.timestamps
    end

    add_index :alerts, :severity
    add_index :alerts, [:ended_at, :started_at]
    add_index :alerts, [:alert_rule_id, :ended_at]
    add_index :alerts, [:measurement_point_id, :ended_at]
  end
end
