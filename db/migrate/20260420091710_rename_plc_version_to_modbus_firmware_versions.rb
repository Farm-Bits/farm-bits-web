class RenamePlcVersionToModbusFirmwareVersions < ActiveRecord::Migration[7.2]
  def change
    rename_table :plc_versions, :modbus_firmware_versions

    add_column :modbus_firmware_versions, :relay_slot_base, :integer, after: :behavior_profile
    add_column :modbus_firmware_versions, :relay_slot_size, :integer, after: :relay_slot_base
    add_column :modbus_firmware_versions, :relay_max_slots, :integer, after: :relay_slot_size
    add_column :modbus_firmware_versions, :relay_register_type, :string, after: :relay_max_slots

    rename_column :interfaces,          :plc_version_id, :modbus_firmware_version_id
    rename_column :plcs,                :plc_version_id, :modbus_firmware_version_id
    rename_column :register_templates,  :plc_version_id, :modbus_firmware_version_id
  end
end
