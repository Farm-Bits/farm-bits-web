class UpdateRegisterTemplateUniquenessForRegisterType < ActiveRecord::Migration[7.2]
  def change
    remove_index :register_templates, column: [:modbus_firmware_version_id, :address], unique: true
    add_index :register_templates, [:modbus_firmware_version_id, :register_type, :address], unique: true
  end
end
