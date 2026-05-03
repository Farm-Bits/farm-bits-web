class AddModbusProtocolSupportToModels < ActiveRecord::Migration[7.2]
  def change
    add_column :models, :supports_modbus_tcp, :boolean, default: false, null: false, after: :display_type
    add_column :models, :supports_modbus_rtu, :boolean, default: false, null: false, after: :supports_modbus_tcp
  end
end
