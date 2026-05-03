class CreateAlertRules < ActiveRecord::Migration[7.2]
  def change
    remove_column :measurement_points, :alarm_low, :decimal
    remove_column :measurement_points, :alarm_high, :decimal
    remove_column :measurement_points, :warning_low, :decimal
    remove_column :measurement_points, :warning_high, :decimal

    create_table :alert_rules do |t|
      t.string :name, null: false
      t.string :severity, null: false
      t.string :condition_type, null: false
      t.string :direction
      t.decimal :threshold_value, precision: 15, scale: 6
      t.integer :inactivity_seconds
      t.integer :min_duration_seconds
      t.boolean :active, null: false, default: true
      t.references :measurement_point, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :alert_rules, :condition_type
    add_index :alert_rules, [:measurement_point_id, :active]
  end
end
