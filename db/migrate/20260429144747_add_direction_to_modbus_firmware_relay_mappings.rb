class AddDirectionToModbusFirmwareRelayMappings < ActiveRecord::Migration[7.2]
  def change
    add_column :modbus_firmware_relay_mappings, :direction, :string, null: false, default: 'read', after: :relay_offset
    change_column_default :modbus_firmware_relay_mappings, :direction, nil

    remove_index :modbus_firmware_relay_mappings, [:modbus_firmware_version_id, :register_template_id]
    add_index :modbus_firmware_relay_mappings, [:modbus_firmware_version_id, :register_template_id, :direction], unique: true

    rename_table :plc_write_logs, :modbus_write_logs
    add_column :modbus_write_logs, :target_type, :string, after: :measurement_point_id
    add_column :modbus_write_logs, :target_id, :integer, after: :target_type
    add_reference :modbus_write_logs, :relay_host_plc, foreign_key: { to_table: :plcs }, after: :target_id

    execute <<~SQL
      UPDATE modbus_write_logs
      SET target_type = 'Plc',
          target_id   = plc_id
      WHERE plc_id IS NOT NULL
    SQL

    change_column_null :modbus_write_logs, :target_type, false
    change_column_null :modbus_write_logs, :target_id,   false

    add_index :modbus_write_logs, [:target_type, :target_id]

    remove_column :modbus_write_logs, :plc_id
  end
end
