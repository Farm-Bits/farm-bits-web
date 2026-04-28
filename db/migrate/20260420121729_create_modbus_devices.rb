class CreateModbusDevices < ActiveRecord::Migration[7.2]
  def change
    create_table :modbus_devices do |t|
      t.string :name, null: false
      t.string :label
      t.integer :slave_id, null: false
      t.string :private_ip
      t.integer :slot_number
      t.datetime :last_seen_at
      t.boolean :active, null: false, default: true
      t.references :model, null: false, foreign_key: true
      t.references :modbus_firmware_version, null: false, foreign_key: true
      t.references :plc, foreign_key: true
      t.references :gateway, foreign_key: true
      t.references :site, foreign_key: true

      t.timestamps
    end

    add_index :modbus_devices, [:plc_id, :slot_number], unique: true
    add_index :modbus_devices, [:gateway_id, :private_ip], unique: true

    add_reference :measurement_points, :modbus_device, null: true, foreign_key: { on_delete: :cascade }, after: :plc_id
    change_column_null :measurement_points, :plc_id, true
  end
end
