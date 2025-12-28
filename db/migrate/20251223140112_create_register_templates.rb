class CreateRegisterTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :register_templates do |t|
      t.string :name, null: false
      t.string :label, null: false
      t.text :description

      # Modbus address configuration
      t.integer :address, null: false
      t.integer :address_count, null: false, default: 1
      t.string :register_type, null: false
      t.string :data_type, null: false
      t.string :byte_order, null: false
      t.decimal :factor, null: false, precision: 15, scale: 10, default: 1.0
      t.decimal :offset, null: false, precision: 15, scale: 6, default: 0.0

      # Register category
      # measurement (linked to MeasurementSubtype, stored in timeseries)
      # configuration (device settings, also stored in timeseries for history)
      # control (commands to device, e.g., set setpoint)
      # status (device status flags, diagnostic info)
      # identification (device info like serial, firmware version)
      t.string :category, null: false

      t.boolean :read_only, null: false, default: true

      # Validation bounds
      t.decimal :min_value, precision: 15, scale: 6
      t.decimal :max_value, precision: 15, scale: 6
      t.decimal :default_value, precision: 15, scale: 6

      # For status/enum registers, define possible values
      # Example: {"0": "Off", "1": "On", "2": "Error"}
      t.jsonb :enum_values, default: {}

      t.boolean :default_data_collection_enabled, null: false, default: true
      t.integer :default_polling_interval_seconds, null: false, default: 60
      t.integer :position, null: false, default: 0
      t.references :interface, foreign_key: { on_delete: :cascade }
      t.references :measurement_subtype, foreign_key: { on_delete: :cascade }
      t.references :plc_version, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :register_templates, [:plc_version_id, :address], unique: true
    add_index :register_templates, [:plc_version_id, :label], unique: true
    add_index :register_templates, [:plc_version_id, :name], unique: true
    add_index :register_templates, :category
    add_index :register_templates, [:plc_version_id, :category]
    add_index :register_templates, [:plc_version_id, :position]
  end
end
