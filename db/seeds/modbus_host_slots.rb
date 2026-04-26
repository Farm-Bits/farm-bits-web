# Usage:
#   rails runner db/seeds/modbus_host_slots.rb

host_version = ModbusFirmwareVersion.first

EEPROM_BASE     = 18810
COMM_STATUS_BASE = 12000
RELAY_MAX_SLOTS = host_version.relay_max_slots

ActiveRecord::Base.transaction do

  position = RegisterTemplate.where(modbus_firmware_version_id: host_version).maximum(:position).to_i + 1

  RELAY_MAX_SLOTS.times do |slot|
    group_name  = "ext_device_#{slot + 1}"
    slot_eeprom = EEPROM_BASE + (slot * 2)            # 2 config regs per slot

    # model_id — firmware_code of the peripheral attached to this slot.
    # Written by ModbusHost#sync_slot; cleared to 0 by #clear_slot.
    RegisterTemplate.create!(
      name:          "Slot #{slot + 1} Model ID",
      label:         "ExternalDeviceSlot#{slot + 1}_ModelId",
      description:   "Peripheral firmware_code for slot #{slot + 1}. 0 = empty.",
      address:       slot_eeprom,
      address_count: 1,
      register_type: 'holding',
      data_type:     'uint16',
      byte_order:    'big_endian',
      value_format:  'numeric',
      factor:        1.0,
      offset:        0.0,
      category:      'configuration',
      group_name:    group_name,
      group_role:    'model_id',
      bulk_read_group: 'ext_device_config',
      bulk_read_address: EEPROM_BASE,
      bulk_read_offset: slot * 2,
      read_only:     false,
      user_visibility: 'hidden',
      min_value:     0,
      max_value:     3,
      default_value: 0,
      position: position,
      modbus_firmware_version: host_version
    )
    position += 1

    # slave_id — Modbus address (1..247) of the peripheral on the RS-485 bus.
    RegisterTemplate.create!(
      name:          "Slot #{slot + 1} Slave ID",
      label:         "ExternalDeviceSlot#{slot + 1}_SlaveId",
      description:   "Peripheral Modbus slave_id for slot #{slot + 1}.",
      address:       slot_eeprom + 1,
      address_count: 1,
      register_type: 'holding',
      data_type:     'uint16',
      byte_order:    'big_endian',
      value_format:  'numeric',
      factor:        1.0,
      offset:        0.0,
      category:      'configuration',
      group_name:    group_name,
      group_role:    'slave_id',
      bulk_read_group: 'ext_device_config',
      bulk_read_address: EEPROM_BASE,
      bulk_read_offset: slot * 2 + 1,
      read_only:     false,
      user_visibility: 'hidden',
      min_value:     0,
      max_value:     247,
      default_value: 0,
      position: position,
      modbus_firmware_version: host_version
    )
    position += 1
  end

  RELAY_MAX_SLOTS.times do |slot|
    group_name  = "ext_device_#{slot + 1}"

    # comm_status — host-synthesized diagnostic, lives at offset 0 of the
    # slot's relay block. 0 = ok, non-zero = error code (firmware-defined).
    RegisterTemplate.create!(
      name:          "Slot #{slot + 1} Comm Status",
      label:         "ExternalDeviceSlot#{slot + 1}_CommStatus",
      description:   "Host-synthesized communication status for slot #{slot + 1}.",
      address:       COMM_STATUS_BASE + slot,
      address_count: 1,
      register_type: 'holding',
      data_type:     'uint16',
      byte_order:    'big_endian',
      value_format:  'enum',
      factor:        1.0,
      offset:        0.0,
      category:      'diagnostic',
      group_name:    group_name,
      group_role:    'comm_status',
      bulk_read_group: 'ext_device_status',
      bulk_read_address: COMM_STATUS_BASE,
      bulk_read_offset: slot,
      read_only:     true,
      user_visibility: 'visible',
      enum_values: {
        '0' => 'OK',
        '1' => 'Timeout reached',
        '2' => 'Modbus exception'
      },
      position: position,
      modbus_firmware_version: host_version
    )
    position += 1
  end

end
