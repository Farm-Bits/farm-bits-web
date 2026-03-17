# Usage:
#   rails runner db/seeds/operation_mode_registers.rb
#

ActiveRecord::Base.transaction do

  OM_BASE_ADDRESS = 16554
  OM_STATUS_BASE_ADDRESS = 9018

  ACTIVE_SOURCE_ENUM = {
    '0' => 'None',
    '1' => 'Manual (Indefinite)',
    '2' => 'Manual (Timed)',
    '3' => 'Schedule 1',
    '4' => 'Schedule 2',
    '5' => 'Schedule 3',
    '6' => 'Schedule 4',
    '7' => 'Schedule 5',
    '8' => 'Schedule 6',
    '9' => 'Duty Cycle',
    '10' => 'Sensor Trigger'
  }.freeze

  OPERATOR_ENUM = {
    '0' => '>',
    '1' => '>=',
    '2' => '<',
    '3' => '<=',
    '4' => '=',
    '5' => '!='
  }.freeze

  OM_SAFETY_REGISTERS = [
    { name: 'Emergency Stop',   group_role: 'emergency_stop',  data_type: 'boolean', value_format: 'boolean',          addr_count: 1, default_value: 0, description: 'Immediately forces output off. Overrides everything.' },
    { name: 'Max ON Enabled',   group_role: 'max_on_enabled',  data_type: 'boolean', value_format: 'boolean',          addr_count: 1, default_value: 0, description: 'Enable maximum on time enforcement.' },
    { name: 'Max ON Time',      group_role: 'max_on',          data_type: 'uint32',  value_format: 'duration_seconds', addr_count: 2, default_value: 1, min_value: 1, visibility_conditions: { 'max_on_enabled' => ['1'] },  validation_rules: { 'required_when' => { 'group_role' => 'max_on_enabled',  'equals' => '1' } }, description: 'Force off after being on this long.' },
    { name: 'Min OFF Enabled',  group_role: 'min_off_enabled', data_type: 'boolean', value_format: 'boolean',          addr_count: 1, default_value: 0, description: 'Enable minimum off time enforcement.' },
    { name: 'Min OFF Time',     group_role: 'min_off',         data_type: 'uint32',  value_format: 'duration_seconds', addr_count: 2, default_value: 1, min_value: 1, visibility_conditions: { 'min_off_enabled' => ['1'] }, validation_rules: { 'required_when' => { 'group_role' => 'min_off_enabled', 'equals' => '1' } }, description: 'Cannot turn back on until off this long.' },
    { name: 'Min ON Enabled',   group_role: 'min_on_enabled',  data_type: 'boolean', value_format: 'boolean',          addr_count: 1, default_value: 0, description: 'Enable minimum on time enforcement.' },
    { name: 'Min ON Time',      group_role: 'min_on',          data_type: 'uint32',  value_format: 'duration_seconds', addr_count: 2, default_value: 1, min_value: 1, visibility_conditions: { 'min_on_enabled' => ['1'] },  validation_rules: { 'required_when' => { 'group_role' => 'min_on_enabled',  'equals' => '1' } }, description: 'Cannot turn off until on this long. Emergency stop overrides.' }
  ].freeze

  # Shared across Duty Cycle + Sensor Triggered (one per output)
  OM_WINDOW_REGISTERS = [
    { name: 'Enabled',         group_role: 'enabled',      data_type: 'boolean', value_format: 'boolean',     addr_count: 1, default_value: 0 },
    { name: 'Start Reference', group_role: 'start_ref',    data_type: 'uint16',  value_format: 'enum',        addr_count: 1, default_value: 0, enum_values: { '0' => 'Fixed', '1' => 'Sunrise', '2' => 'Sunset' }, description: 'Time reference for window start.' },
    { name: 'Start Time',      group_role: 'start_time',   data_type: 'uint16',  value_format: 'time_of_day', addr_count: 1, default_value: 0, visibility_conditions: { 'start_ref' => ['0'] }, description: 'Window start as minutes since midnight.' },
    { name: 'Start Offset',    group_role: 'start_offset', data_type: 'int16',   value_format: 'numeric',     addr_count: 1, default_value: 0, min_value: -1439, max_value: 1439, visibility_conditions: { 'start_ref' => ['1', '2'] }, description: 'Signed offset from sunrise/sunset for window start.' },
    { name: 'End Reference',   group_role: 'end_ref',      data_type: 'uint16',  value_format: 'enum',        addr_count: 1, default_value: 0, enum_values: { '0' => 'Fixed', '1' => 'Sunrise', '2' => 'Sunset' }, description: 'Time reference for window end.' },
    { name: 'End Time',        group_role: 'end_time',     data_type: 'uint16',  value_format: 'time_of_day', addr_count: 1, default_value: 0, visibility_conditions: { 'end_ref' => ['0'] }, description: 'Window end as minutes since midnight.' },
    { name: 'End Offset',      group_role: 'end_offset',   data_type: 'int16',   value_format: 'numeric',     addr_count: 1, default_value: 0, min_value: -1439, max_value: 1439, visibility_conditions: { 'end_ref' => ['1', '2'] }, description: 'Signed offset from sunrise/sunset for window end.' },
    { name: 'Days',            group_role: 'days',         data_type: 'uint16',  value_format: 'bitmask',     addr_count: 1, default_value: 0, enum_values: { '0' => 'Sunday', '1' => 'Monday', '2' => 'Tuesday', '3' => 'Wednesday', '4' => 'Thursday', '5' => 'Friday', '6' => 'Saturday' }, description: 'Days the window is active.' }
  ].freeze

  OM_STATUS_REGISTERS = [
    { name: 'Active Source',  group_role: 'active_source',    data_type: 'uint16', value_format: 'enum',             addr_count: 1, read_only: true, enum_values: ACTIVE_SOURCE_ENUM, description: 'What is currently controlling this output.' },
    { name: 'Error Flags',    group_role: 'error_flags',      data_type: 'uint16', value_format: 'bitmask',          addr_count: 1, read_only: true, enum_values: { '0' => 'Max ON exceeded', '1' => 'Min OFF active', '2' => 'Sensor error', '3' => 'Blackout active' }, description: 'Active safety or error conditions.' },
    { name: 'Next Change In', group_role: 'next_change_time', data_type: 'uint32', value_format: 'duration_seconds', addr_count: 2, read_only: true, description: 'Seconds until next predicted state change.' }
  ].freeze

  OM_MANUAL_REGISTERS = [
    { name: 'Command',  group_role: 'command',  data_type: 'uint16', value_format: 'enum',             addr_count: 1, default_value: 0, enum_values: { '0' => 'None', '1' => 'Turn On', '2' => 'Turn On (Timed)', '3' => 'Turn Off' }, description: 'Manual command. PLC resets to None after executing.' },
    { name: 'Duration', group_role: 'duration', data_type: 'uint32', value_format: 'duration_seconds', addr_count: 2, default_value: 1, min_value: 1, visibility_conditions: { 'command' => ['2'] }, validation_rules: { 'required_when' => { 'group_role' => 'command', 'equals' => '2' } }, description: 'Duration for Turn On (Timed).' }
  ].freeze

  OM_DUTY_CYCLE_REGISTERS = [
    { name: 'Enabled',      group_role: 'enabled',      data_type: 'boolean', value_format: 'boolean',          addr_count: 1, default_value: 0, description: 'Master toggle for duty cycle mode' },
    { name: 'ON Duration',  group_role: 'on_duration',  data_type: 'uint32',  value_format: 'duration_seconds', addr_count: 2, default_value: 1, min_value: 1, validation_rules: { 'required_when' => { 'group_role' => 'enabled', 'equals' => '1' } }, description: 'ON phase length in seconds.' },
    { name: 'OFF Duration', group_role: 'off_duration', data_type: 'uint32',  value_format: 'duration_seconds', addr_count: 2, default_value: 1, min_value: 1, validation_rules: { 'required_when' => { 'group_role' => 'enabled', 'equals' => '1' } }, description: 'OFF phase length in seconds.' }
  ].freeze

  OM_SENSOR_REGISTERS = [
    { name: 'Enabled', group_role: 'enabled', data_type: 'boolean', value_format: 'boolean', addr_count: 1, default_value: 0, description: 'Master toggle for sensor trigger mode' }
  ].freeze

  SENSOR_CONDITION_REGISTERS = [
    { name: 'Enabled',        group_role: 'enabled',        data_type: 'boolean', value_format: 'boolean', addr_count: 1, default_value: 0 },
    { name: 'Source Type',    group_role: 'source_type',    data_type: 'uint16',  value_format: 'enum',    addr_count: 1, default_value: 0, enum_values: { '1' => 'AI', '2' => 'DI', '3' => 'DO', '4' => 'AO' }, validation_rules: { 'required_when' => { 'group_role' => 'enabled', 'equals' => '1' } }, description: 'IO type to monitor.' },
    { name: 'Source Number',  group_role: 'source_io_number', data_type: 'uint16', value_format: 'numeric', addr_count: 1, default_value: 1, min_value: 1, max_value: 12, validation_rules: { 'required_when' => { 'group_role' => 'enabled', 'equals' => '1' } }, description: 'Interface number within selected type (e.g. 3 = AI3).' },
    { name: 'Operator',       group_role: 'operator',       data_type: 'uint16',  value_format: 'enum',    addr_count: 1, default_value: 0, enum_values: OPERATOR_ENUM, description: 'Comparison operator.' },
    { name: 'Threshold',      group_role: 'threshold',      data_type: 'int16',   value_format: 'numeric', addr_count: 1, default_value: 0, validation_rules: { 'required_when' => { 'group_role' => 'enabled', 'equals' => '1' } }, description: 'Comparison value in raw PLC units. For DI/DO: 0 or 1.' },
    { name: 'Hysteresis',     group_role: 'hysteresis',     data_type: 'uint16',  value_format: 'numeric', addr_count: 1, default_value: 0, description: 'Deadband in raw units. 0 for DI/DO sources.' }
  ].freeze

  SCHEDULE_SLOT_REGISTERS = [
    { name: 'Enabled',         group_role: 'enabled',       data_type: 'boolean', value_format: 'boolean',     addr_count: 1, default_value: 0 },
    { name: 'Action',          group_role: 'action',        data_type: 'uint16',  value_format: 'enum',        addr_count: 1, default_value: 0, enum_values: { '0' => 'Turn On', '1' => 'Start Duty Cycle' }, description: 'Turn On = direct output for duration. Start Duty Cycle = run on/off pattern for duration.' },
    { name: 'Start Reference', group_role: 'start_ref',     data_type: 'uint16',  value_format: 'enum',        addr_count: 1, default_value: 0, enum_values: { '0' => 'Fixed', '1' => 'Sunrise', '2' => 'Sunset' }, description: 'Time reference for start.' },
    { name: 'Start Time',      group_role: 'start_time',    data_type: 'uint16',  value_format: 'time_of_day', addr_count: 1, default_value: 0, description: 'Absolute start time as minutes since midnight.', visibility_conditions: { 'start_ref' => ['0'] } },
    { name: 'Start Offset',    group_role: 'start_offset',  data_type: 'int16',   value_format: 'numeric',     addr_count: 1, default_value: 0, min_value: -1439, max_value: 1439, description: 'Signed offset in minutes from sunrise/sunset.', visibility_conditions: { 'start_ref' => ['1', '2'] } },
    { name: 'Duration',        group_role: 'duration',      data_type: 'uint32',  value_format: 'duration_seconds', addr_count: 2, default_value: 1, min_value: 1, description: 'How long to run in seconds. For Turn On: output stays on. For Duty Cycle: total cycling time.', validation_rules: { 'required_when' => { 'group_role' => 'enabled', 'equals' => '1' } } },
    { name: 'Schedule Type',   group_role: 'schedule_type', data_type: 'uint16',  value_format: 'enum',        addr_count: 1, default_value: 0, enum_values: { '0' => 'Recurring', '1' => 'One-time' }, description: 'Whether this slot repeats weekly or fires once.' },
    { name: 'Days',            group_role: 'days',          data_type: 'uint16',  value_format: 'bitmask',     addr_count: 1, default_value: 0, min_value: 0, max_value: 127, enum_values: { '0' => 'Sunday', '1' => 'Monday', '2' => 'Tuesday', '3' => 'Wednesday', '4' => 'Thursday', '5' => 'Friday', '6' => 'Saturday' }, validation_rules: { 'required_when' => { 'group_role' => 'schedule_type', 'equals' => '0' } }, visibility_conditions: { 'schedule_type' => ['0'] } },
    { name: 'One-time Day',    group_role: 'onetime_day',   data_type: 'uint16',  value_format: 'numeric',     addr_count: 1, default_value: 0, min_value: 1, max_value: 31, validation_rules: { 'required_when' => { 'group_role' => 'schedule_type', 'equals' => '1' } }, visibility_conditions: { 'schedule_type' => ['1'] } },
    { name: 'One-time Month',  group_role: 'onetime_month', data_type: 'uint16',  value_format: 'numeric',     addr_count: 1, default_value: 0, min_value: 1, max_value: 12, validation_rules: { 'required_when' => { 'group_role' => 'schedule_type', 'equals' => '1' } }, visibility_conditions: { 'schedule_type' => ['1'] } },
    { name: 'One-time Year',   group_role: 'onetime_year',  data_type: 'uint16',  value_format: 'numeric',     addr_count: 1, default_value: 0, min_value: 2020, max_value: 9999, description: 'Used by backend for cleanup.', validation_rules: { 'required_when' => { 'group_role' => 'schedule_type', 'equals' => '1' } }, visibility_conditions: { 'schedule_type' => ['1'] } }
  ].freeze

  PLC_VERSION_ID = PlcVersion.first.id

  def create_register(interface, group_name, address, current_position, interface_register_mapping_position, reg)
    group_label = group_name.split('_')
    group_label.shift
    group_label = group_label.join(' ').titleize.split(' ').join('')

    label = "DO#{interface.io_number}_OM_#{group_label}_#{reg[:name].split(' ').join('')}"
    read_only = reg[:read_only] || false

    register_template = RegisterTemplate.create!(
      name: reg[:name],
      label: label,
      description: reg[:description],
      address: address,
      address_count: reg[:addr_count],
      register_type: 'holding',
      data_type: reg[:data_type],
      byte_order: 'big_endian',
      value_format: reg[:value_format],
      factor: 1.0,
      offset: 0.0,
      category: !read_only ? 'operation_mode_configuration' : 'operation_mode_status',
      group_name: group_name,
      group_role: reg[:group_role],
      validation_rules: reg[:validation_rules],
      visibility_conditions: reg[:visibility_conditions],
      bulk_read_group: !read_only ? "DO#{interface.io_number}_operation_mode_configuration" : "DO#{interface.io_number}_operation_mode_status",
      bulk_read_address: !read_only ? OM_BASE_ADDRESS : OM_STATUS_BASE_ADDRESS,
      bulk_read_offset: !read_only ? address - OM_BASE_ADDRESS : address - OM_STATUS_BASE_ADDRESS,
      read_only: read_only,
      user_visibility: 'visible',
      min_value: reg[:min_value],
      max_value: reg[:max_value],
      default_value: reg[:default_value],
      enum_values: reg[:enum_values],
      position: current_position,
      plc_version_id: PLC_VERSION_ID
    )
    InterfaceRegisterMapping.create!(
      description: reg[:description],
      position: interface_register_mapping_position,
      interface: interface,
      register_template: register_template
    )
  end

  current_position = RegisterTemplate.where(plc_version_id: PLC_VERSION_ID).maximum(:position).to_i + 1
  address_offset = 0
  address_status_offset = 0

  (1..12).each do |n|
    interface = Interface.find_by(communication_type: 'digital_output', io_number: n, plc_version_id: PLC_VERSION_ID)
    interface_register_mapping_position = InterfaceRegisterMapping.where(interface: interface).maximum(:position).to_i + 1

    [
      { registers: OM_SAFETY_REGISTERS,        group_name: 'om_safety',      status: false, slots: 1 },
      { registers: OM_WINDOW_REGISTERS,        group_name: 'om_window',      status: false, slots: 1 },
      { registers: OM_STATUS_REGISTERS,        group_name: 'om_status',      status: true,  slots: 1 },
      { registers: OM_MANUAL_REGISTERS,        group_name: 'om_manual',      status: false, slots: 1 },
      { registers: OM_DUTY_CYCLE_REGISTERS,    group_name: 'om_duty_cycle',  status: false, slots: 1 },
      { registers: OM_SENSOR_REGISTERS,        group_name: 'om_sensor',      status: false, slots: 1 },
      { registers: SENSOR_CONDITION_REGISTERS, group_name: 'om_sensor_cond', status: false, slots: 11 },
      { registers: SCHEDULE_SLOT_REGISTERS,    group_name: 'om_schedule',    status: false, slots: 6 }
    ].each do |reg_group|

      reg_group[:slots].times do |slot_number|
        reg_group[:registers].each do |reg|

          address = reg_group[:status] ? OM_STATUS_BASE_ADDRESS + address_status_offset : OM_BASE_ADDRESS + address_offset
          group_name = reg_group[:group_name]
          if reg_group[:slots] > 1
            group_name += "_#{slot_number + 1}"
          end

          create_register(interface, group_name, address, current_position, interface_register_mapping_position, reg)

          if reg_group[:status]
            address_status_offset += reg[:addr_count]
          else
            address_offset += reg[:addr_count]
          end

          current_position += 1
          interface_register_mapping_position += 1
        end
      end
    end

  end
end
