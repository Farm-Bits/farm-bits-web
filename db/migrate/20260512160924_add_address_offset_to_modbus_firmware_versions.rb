class AddAddressOffsetToModbusFirmwareVersions < ActiveRecord::Migration[7.2]
  def change
    add_column :modbus_firmware_versions, :address_offset, :integer, null: false, after: :version_code
  end
end
