# Creates RegisterTemplates:
#   - Sunrise / Sunset (group_name: 'sun_data')
#   - IO Active Bitmasks (group_name: 'io_active')
#   - Push Data Thresholds - AI (group_name: 'push_data_config')
#   - Push Data Thresholds - DI counters (group_name: 'push_data_config')
#
# Usage:
#   rails runner db/seeds/phase2_global_registers.rb
#

ActiveRecord::Base.transaction do
  # ============================================================
  # Configuration — set your actual addresses here
  # ============================================================

  # Sunrise/Sunset addresses
  SUN_DATA_BASE_ADDRESS = 16450

  # IO Active Bitmask addresses
  IO_ACTIVE_BASE_ADDRESS = 16452

  # Push threshold addresses
  PUSH_THRESHOLD_BASE_ADDRESS = 16494

  # ============================================================
  # Register definitions
  # ============================================================

  SUN_DATA_REGISTERS = [
    {
      name: 'Sunrise Minutes',
      label: 'SunriseMinutes',
      description: 'Minutes since midnight (site-local time) until sunrise',
      address_count: 1,
      group_role: 'sunrise',
      default_value: 360
    },
    {
      name: 'Sunset Minutes',
      label: 'SunsetMinutes',
      description: 'Minutes since midnight (site-local time) until sunset',
      address_count: 1,
      group_role: 'sunset',
      default_value: 1080
    }
  ].freeze

  DI_ACTIVE_REGISTERS = (1..12).map do |n|
    {
      label: "DI#{n}_Active",
      name: "DI#{n} Active",
      description: "Whether DI#{n} is active (1) or not (0)",
      address_count: 1,
      group_role: "active_di_#{n}",
      communication_type: "digital_input",
      io_number: n
    }
  end
  AI_ACTIVE_REGISTERS = (1..12).map do |n|
    {
      label: "AI#{n}_Active",
      name: "AI#{n} Active",
      description: "Whether AI#{n} is active (1) or not (0)",
      address_count: 1,
      group_role: "active_ai_#{n}",
      communication_type: "analog_input",
      io_number: n
    }
  end
  AO_ACTIVE_REGISTERS = (1..6).map do |n|
    {
      label: "AO#{n}_Active",
      name: "AO#{n} Active",
      description: "Whether AO#{n} is active (1) or not (0)",
      address_count: 1,
      group_role: "active_ao_#{n}",
      communication_type: "analog_output",
      io_number: n
    }
  end
  DO_ACTIVE_REGISTERS = (1..12).map do |n|
    {
      label: "DO#{n}_Active",
      name: "DO#{n} Active",
      description: "Whether DO#{n} is active (1) or not (0)",
      address_count: 1,
      group_role: "active_do_#{n}",
      communication_type: "digital_output",
      io_number: n
    }
  end
  IO_ACTIVE_REGISTERS = DI_ACTIVE_REGISTERS + AI_ACTIVE_REGISTERS + AO_ACTIVE_REGISTERS + DO_ACTIVE_REGISTERS

  PUSH_THRESHOLD_DI_COUNTER_REGISTERS = (1..12).map do |n|
    {
      name: "Counter Push Threshold",
      label: "DI#{n}_CounterPushThreshold",
      description: "DI#{n} counter minimum absolute change to trigger push. Applicable only if DI#{n} is configured as counter and active. Value is in counts.",
      address_count: 1,
      group_role: "threshold_di_counter_#{n}",
      default_value: 1,
      min_value: 0,
      max_value: 65535,
      communication_type: "digital_input",
      io_number: n
    }
  end.freeze
  PUSH_THRESHOLD_AI_REGISTERS = (1..12).map do |n|
    {
      name: "Push Threshold",
      label: "AI#{n}_PushThreshold",
      description: "AI#{n} minimum percentage change threshold to trigger push",
      address_count: 1,
      group_role: "threshold_ai_#{n}",
      factor: 10,
      default_value: 20,
      min_value: 0,
      max_value: 100,
      communication_type: "analog_input",
      io_number: n
    }
  end.freeze
  PUSH_THRESHOLD_REGISTERS = PUSH_THRESHOLD_DI_COUNTER_REGISTERS + PUSH_THRESHOLD_AI_REGISTERS

  MODBUS_FIRMWARE_VERSION_ID = ModbusFirmwareVersion.first.id

  # ============================================================
  # Seeding logic
  # ============================================================

  current_position = RegisterTemplate.where(modbus_firmware_version_id: MODBUS_FIRMWARE_VERSION_ID).maximum(:position).to_i + 1

  # Sunrise / Sunset
  address_offset = 0
  SUN_DATA_REGISTERS.each do |reg|
    RegisterTemplate.create!(
      name: reg[:name],
      label: reg[:label],
      description: reg[:description],
      address: SUN_DATA_BASE_ADDRESS + address_offset,
      address_count: reg[:address_count],
      register_type: 'holding',
      data_type: 'uint16',
      byte_order: 'big_endian',
      value_format: 'time_of_day',
      factor: 1.0,
      offset: 0.0,
      category: 'configuration',
      group_name: 'sun_data',
      group_role: reg[:group_role],
      bulk_read_group: 'sun_data',
      bulk_read_address: SUN_DATA_BASE_ADDRESS,
      bulk_read_offset: address_offset,
      read_only: false,
      user_visibility: 'hidden',
      default_value: reg[:default_value],
      position: current_position,
      modbus_firmware_version_id: MODBUS_FIRMWARE_VERSION_ID
    )

    address_offset += reg[:address_count]
    current_position += 1
  end

  # # IO Active
  address_offset = 0
  IO_ACTIVE_REGISTERS.each do |reg|
    register_template = RegisterTemplate.create!(
      name: reg[:name],
      label: reg[:label],
      description: reg[:description],
      address: IO_ACTIVE_BASE_ADDRESS + address_offset,
      address_count: reg[:address_count],
      register_type: 'holding',
      data_type: 'boolean',
      byte_order: 'big_endian',
      value_format: 'boolean',
      factor: 1.0,
      offset: 0.0,
      category: 'interface_configuration',
      group_name: 'io_active',
      group_role: reg[:group_role],
      bulk_read_group: 'io_active',
      bulk_read_address: IO_ACTIVE_BASE_ADDRESS,
      bulk_read_offset: address_offset,
      read_only: false,
      user_visibility: 'hidden',
      default_value: 0,
      position: current_position,
      modbus_firmware_version_id: MODBUS_FIRMWARE_VERSION_ID
    )

    interface = Interface.find_by(communication_type: reg[:communication_type], io_number: reg[:io_number], modbus_firmware_version_id: MODBUS_FIRMWARE_VERSION_ID)
    last_position = InterfaceRegisterMapping.where(interface: interface).maximum(:position).to_i + 1
    InterfaceRegisterMapping.create!(
      description: reg[:description],
      position: last_position,
      interface: interface,
      register_template: register_template
    )

    address_offset += reg[:address_count]
    current_position += 1
  end

  # # Push Thresholds
  address_offset = 0
  PUSH_THRESHOLD_REGISTERS.each do |reg|
    register_template = RegisterTemplate.create!(
      name: reg[:name],
      label: reg[:label],
      description: reg[:description],
      address: PUSH_THRESHOLD_BASE_ADDRESS + address_offset,
      address_count: reg[:address_count],
      register_type: 'holding',
      data_type: 'uint16',
      byte_order: 'big_endian',
      value_format: 'numeric',
      factor: 1.0,
      offset: 0.0,
      category: 'interface_configuration',
      group_name: 'push_data_thresholds',
      group_role: reg[:group_role],
      bulk_read_group: 'push_data_thresholds',
      bulk_read_address: PUSH_THRESHOLD_BASE_ADDRESS,
      bulk_read_offset: address_offset,
      read_only: false,
      user_visibility: 'visible',
      min_value: reg[:min_value],
      max_value: reg[:max_value],
      default_value: reg[:default_value],
      position: current_position,
      modbus_firmware_version_id: MODBUS_FIRMWARE_VERSION_ID
    )

    interface = Interface.find_by(communication_type: reg[:communication_type], io_number: reg[:io_number], modbus_firmware_version_id: MODBUS_FIRMWARE_VERSION_ID)
    last_position = InterfaceRegisterMapping.where(interface: interface).maximum(:position).to_i + 1
    InterfaceRegisterMapping.create!(
      description: reg[:description],
      position: last_position,
      interface: interface,
      register_template: register_template
    )

    address_offset += reg[:address_count]
    current_position += 1
  end
end
