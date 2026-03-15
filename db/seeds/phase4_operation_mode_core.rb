# Creates RegisterTemplates, InterfaceRegisterMappings
# for the core operation mode registers on digital_output interfaces:
#
#   om_status  - Read-only status (output_state, active_source, timers, predictions)
#   om_manual  - Manual ON/OFF control with duration
#   om_safety  - Safety constraints (max_on, min_off, min_on, blackout, emergency)
#
# These are the priority layers 1–4 of the control loop:
#   Emergency → Blackout → Safety limits → Manual override
#
# No automation (schedule, duty cycle, sensor trigger) in this phase.
#
# Usage:
#   rails runner db/seeds/phase4_operation_mode_core.rb
#

ActiveRecord::Base.transaction do
  OM_BASE_ADDRESS = 16554
  OM_STATUS_BASE_ADDRESS = 9018

  ACTIVE_SOURCE_ENUM = {
    '0' => 'none',
    '1' => 'manual',
    '2' => 'schedule',
    '3' => 'duty_cycle',
    '4' => 'sensor_trigger',
    '5' => 'emergency',
    '6' => 'blackout',
    '7' => 'safety_limit'
  }.freeze

  OM_STATUS_REGISTERS = [
    { group_role: 'output_state',       data_type: 'boolean', value_format: 'boolean',          addr_count: 1 },
    { group_role: 'active_source',      data_type: 'uint16',  value_format: 'enum',             addr_count: 1, enum_values: ACTIVE_SOURCE_ENUM },
    { group_role: 'manual_remaining',   data_type: 'uint32',  value_format: 'duration_seconds', addr_count: 2 },
    { group_role: 'duty_remaining',     data_type: 'uint32',  value_format: 'duration_seconds', addr_count: 2 },
    { group_role: 'duty_phase',         data_type: 'uint16',  value_format: 'enum',             addr_count: 1, enum_values: { '0' => 'inactive', '1' => 'on_phase', '2' => 'off_phase' } },
    { group_role: 'on_elapsed',         data_type: 'uint32',  value_format: 'duration_seconds', addr_count: 2 },
    { group_role: 'off_elapsed',        data_type: 'uint32',  value_format: 'duration_seconds', addr_count: 2 },
    { group_role: 'error_flags',        data_type: 'uint16',  value_format: 'bitmask',          addr_count: 1, enum_values: { '0' => 'Max ON exceeded', '1' => 'Min OFF active', '2' => 'Sensor error', '3' => 'Blackout active' } },
    { group_role: 'sensor_result',      data_type: 'boolean', value_format: 'boolean',          addr_count: 1 },
    { group_role: 'next_change_time',   data_type: 'uint32',  value_format: 'duration_seconds', addr_count: 2 },
    { group_role: 'next_change_target', data_type: 'uint16',  value_format: 'enum',             addr_count: 1, enum_values: { '0' => 'off', '1' => 'on' } },
    { group_role: 'next_change_source', data_type: 'uint16',  value_format: 'enum',             addr_count: 1, enum_values: ACTIVE_SOURCE_ENUM }
  ].freeze

  OM_MANUAL_REGISTERS = [
    { group_role: 'command',  data_type: 'uint16', value_format: 'enum',             addr_count: 1, enum_values: { '0' => 'none', '1' => 'turn_on', '2' => 'turn_off', '3' => 'release' }, min_value: 0, max_value: 3 },
    { group_role: 'duration', data_type: 'uint32', value_format: 'duration_seconds', addr_count: 2, description: '0 = until manually released.' }
  ].freeze

  OM_SAFETY_REGISTERS = [
    { group_role: 'max_on',          data_type: 'uint32',  value_format: 'duration_seconds', addr_count: 2, description: '0 = no limit.' },
    { group_role: 'min_off',         data_type: 'uint32',  value_format: 'duration_seconds', addr_count: 2, description: '0 = no limit.', validation_rules: { 'greater_than' => { 'group_role' => 'min_on' }, 'message' => 'must exceed minimum on time' } },
    { group_role: 'min_on',          data_type: 'uint32',  value_format: 'duration_seconds', addr_count: 2, description: '0 = no limit. Emergency stop ignores this.' },
    { group_role: 'blackout_start',  data_type: 'uint16',  value_format: 'numeric',          addr_count: 1, min_value: 0, max_value: 1439, description: 'Local minutes since midnight.' },
    { group_role: 'blackout_end',    data_type: 'uint16',  value_format: 'numeric',          addr_count: 1, min_value: 0, max_value: 1439, description: 'Local minutes since midnight. If start > end, wraps past midnight.' },
    { group_role: 'blackout_days',   data_type: 'uint16',  value_format: 'bitmask',          addr_count: 1, min_value: 0, max_value: 127, description: 'Bitmask. bit0=Sun..bit6=Sat. 0 = blackout disabled.', enum_values: {
      '0' => 'Sun', '1' => 'Mon', '2' => 'Tue', '3' => 'Wed', '4' => 'Thu', '5' => 'Fri', '6' => 'Sat' } },
    { group_role: 'emergency',       data_type: 'boolean', value_format: 'boolean',          addr_count: 1, description: 'Write 1 to engage, 0 to release. Overrides everything including min_on.' }
  ].freeze

  PLC_VERSION_ID = PlcVersion.first.id

  def create_register(interface, group_name, address_offset, read_only, current_position, interface_register_mapping_position, reg)
    group_label = group_name.split('_').last
    name = "DO#{interface.io_number} Operation Mode #{group_label.titleize} #{reg[:group_role].humanize.titleize}"
    label = "DO#{interface.io_number}_OM_#{group_label.titleize}_#{reg[:group_role].humanize.titleize.split(' ').join('_')}"
    description = name
    if reg[:enum_values]
      description = "#{name}. #{reg[:enum_values].map { |k, v| "#{k}=#{v}" }.join('. ')}."
    end
    if reg[:description]
      description = "#{description}. #{reg[:description]}"
    end

    is_status = group_name == 'om_status'

    register_template = RegisterTemplate.create!(
      name: name,
      label: label,
      description: description,
      address: !is_status ? OM_BASE_ADDRESS + address_offset : OM_STATUS_BASE_ADDRESS + address_offset,
      address_count: reg[:addr_count],
      register_type: 'holding',
      data_type: reg[:data_type],
      byte_order: 'big_endian',
      value_format: reg[:value_format],
      factor: 1.0,
      offset: 0.0,
      category: !is_status ? 'operation_mode_configuration' : 'operation_mode_status',
      group_name: group_name,
      group_role: reg[:group_role],
      validation_rules: reg[:validation_rules],
      read_only: read_only,
      user_visibility: 'visible',
      min_value: reg[:min_value],
      max_value: reg[:max_value],
      default_value: 0,
      enum_values: reg[:enum_values],
      position: current_position,
      plc_version_id: PLC_VERSION_ID
    )
    InterfaceRegisterMapping.create!(
      description: description,
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

    OM_STATUS_REGISTERS.each do |reg|
      create_register(interface, 'om_status', address_status_offset, true, current_position, interface_register_mapping_position, reg)

      address_status_offset += reg[:addr_count]
      current_position += 1
      interface_register_mapping_position += 1
    end

    OM_MANUAL_REGISTERS.each do |reg|
      create_register(interface, 'om_manual', address_offset, false, current_position, interface_register_mapping_position, reg)

      address_offset += reg[:addr_count]
      current_position += 1
      interface_register_mapping_position += 1
    end

    OM_SAFETY_REGISTERS.each do |reg|
      create_register(interface, 'om_safety', address_offset, false, current_position, interface_register_mapping_position, reg)

      address_offset += reg[:addr_count]
      current_position += 1
      interface_register_mapping_position += 1
    end
  end
end
