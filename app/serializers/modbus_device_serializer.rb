class ModbusDeviceSerializer < Blueprinter::Base
  identifier :id

  fields :name,
    :label,
    :slave_id,
    :private_ip,
    :slot_number,
    :active,
    :last_seen_at

  association :model, blueprint: ModelSerializer
  association :modbus_firmware_version, blueprint: ModbusFirmwareVersionSerializer
end
