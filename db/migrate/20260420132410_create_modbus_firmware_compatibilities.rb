class CreateModbusFirmwareCompatibilities < ActiveRecord::Migration[7.2]
  def change
    create_table :modbus_firmware_compatibilities do |t|
      t.references :host_version, null: false, foreign_key: { on_delete: :cascade, to_table: :modbus_firmware_versions }
      t.references :peripheral_version, null: false, foreign_key: { on_delete: :cascade, to_table: :modbus_firmware_versions }
      t.integer :firmware_code

      t.timestamps
    end

    add_index :modbus_firmware_compatibilities, [:host_version_id, :peripheral_version_id], unique: true
    add_index :modbus_firmware_compatibilities, [:host_version_id, :firmware_code], unique: true
  end
end
