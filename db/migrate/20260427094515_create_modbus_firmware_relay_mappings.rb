class CreateModbusFirmwareRelayMappings < ActiveRecord::Migration[7.2]
  def change
    create_table :modbus_firmware_relay_mappings do |t|
      t.references :modbus_firmware_version, null: false, foreign_key: { on_delete: :cascade }
      t.references :register_template, null: false, foreign_key: { on_delete: :cascade }
      t.integer :relay_offset, null: false

      t.timestamps
    end

    add_index :modbus_firmware_relay_mappings, [:modbus_firmware_version_id, :register_template_id], unique: true
    add_index :modbus_firmware_relay_mappings, [:modbus_firmware_version_id, :relay_offset]
  end
end
