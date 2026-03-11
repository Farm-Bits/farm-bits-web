# Creates RegisterTemplates, InterfaceRegisterMappings
# for sensor trigger on digital_output interfaces.
#
# Per DO:
#   om_sensor          - Master enable (1 register)
#   om_sensor_window   - Optional time window (6 registers)
#   om_sensor_cond_1..11 - Up to 11 conditions (7 registers each = 77 registers)
#
# Conditions reference IOs via source_type + source_io_number:
#   source_type:      0=disabled, 1=AI, 2=DI, 3=DO, 4=AO
#   source_io_number: interface io_number within that type (1-based)
#
# The source_type enum_values are fixed. The frontend dynamically populates
# the source_io_number dropdown from the PlcVersion's interfaces filtered
# by the selected source_type.
#
# NOTE: Replace base addresses with actual Modbus addresses from PLC firmware.
#
# Usage:
#   rails runner db/seeds/phase7_sensor_trigger.rb
#

ActiveRecord::Base.transaction do
  OM_SENSOR_BASE_ADDRESS = 17442
  CONDITIONS_PER_DO = 11

  SOURCE_TYPE_ENUM = {
    '0' => 'disabled',
    '1' => 'AI',
    '2' => 'DI',
    '3' => 'DO',
    '4' => 'AO'
  }.freeze

  OPERATOR_ENUM = {
    '0' => '>',
    '1' => '>=',
    '2' => '<',
    '3' => '<=',
    '4' => '=',
    '5' => '!='
  }.freeze

  LOGIC_ENUM = {
    '0' => 'OR',
    '1' => 'AND'
  }.freeze

  ERROR_BEHAVIOR_ENUM = {
    '0' => 'ignore',
    '1' => 'force_on',
    '2' => 'force_off'
  }.freeze

  OM_SENSOR_REGISTERS = [
    {
      group_role: 'enabled',
      data_type: 'boolean',
      value_format: 'boolean',
      addr_count: 1,
      offset: 0,
      description: 'Master toggle for sensor trigger mode.'
    }
  ].freeze

  OM_SENSOR_WINDOW_REGISTERS = [
    {
      group_role: 'start_ref',
      data_type: 'uint16',
      value_format: 'enum',
      addr_count: 1,
      offset: 0,
      min_value: 0,
      max_value: 2,
      enum_values: { '0' => 'fixed', '1' => 'sunrise', '2' => 'sunset' },
      visibility_conditions: { 'enabled' => ['1'] }
    },
    {
      group_role: 'start_time',
      data_type: 'int16',
      value_format: 'numeric',
      addr_count: 1,
      offset: 1,
      min_value: -1439,
      max_value: 1439,
      visibility_conditions: { 'enabled' => ['1'] }
    },
    {
      group_role: 'end_ref',
      data_type: 'uint16',
      value_format: 'enum',
      addr_count: 1,
      offset: 2,
      min_value: 0,
      max_value: 2,
      enum_values: { '0' => 'fixed', '1' => 'sunrise', '2' => 'sunset' },
      visibility_conditions: { 'enabled' => ['1'] }
    },
    {
      group_role: 'end_time',
      data_type: 'int16',
      value_format: 'numeric',
      addr_count: 1,
      offset: 3,
      min_value: -1439,
      max_value: 1439,
      visibility_conditions: { 'enabled' => ['1'] }
    },
    {
      group_role: 'days',
      data_type: 'uint16',
      value_format: 'numeric',
      addr_count: 1,
      offset: 4,
      min_value: 0,
      max_value: 127,
      description: '0 = always active (no window).',
      visibility_conditions: { 'enabled' => ['1'] }
    },
    {
      group_role: 'onetime_date',
      data_type: 'uint16',
      value_format: 'numeric',
      addr_count: 1,
      offset: 5,
      min_value: 0,
      max_value: 1231,
      description: 'Encoded month×100+day. 0 = recurring.',
      visibility_conditions: { 'enabled' => ['1'] }
    }
  ].freeze

  SENSOR_CONDITION_REGISTERS = [
    {
      group_role: 'source_type',
      data_type: 'uint16',
      value_format: 'enum',
      addr_count: 1,
      offset: 0,
      min_value: 0,
      max_value: 4,
      enum_values: SOURCE_TYPE_ENUM,
      description: 'IO type to monitor. 0 = condition disabled.',
      visibility_conditions: { 'enabled' => ['1'] }
    },
    {
      group_role: 'source_io_number',
      data_type: 'uint16',
      value_format: 'numeric',
      addr_count: 1,
      offset: 1,
      min_value: 0,
      max_value: 255,
      description: 'Interface io_number within the selected type. E.g., 3 = AI3 when source_type=1.',
      visibility_conditions: { 'enabled' => ['1'] },
      validation_rules: {
        'required_when' => { 'group_role' => 'source_type', 'not_equals' => '0' },
        'greater_than_value' => 0
      }
    },
    {
      group_role: 'operator',
      data_type: 'uint16',
      value_format: 'enum',
      addr_count: 1,
      offset: 2,
      min_value: 0,
      max_value: 5,
      enum_values: OPERATOR_ENUM,
      visibility_conditions: { 'enabled' => ['1'] }
    },
    {
      group_role: 'threshold',
      data_type: 'int16',
      value_format: 'numeric',
      addr_count: 1,
      offset: 3,
      min_value: -32768,
      max_value: 32767,
      description: 'In raw PLC units. Backend reverse-scales from display units for AI/AO sources. For DI/DO: 0 or 1.',
      visibility_conditions: { 'enabled' => ['1'] },
      validation_rules: {
        'required_when' => { 'group_role' => 'source_type', 'not_equals' => '0' }
      }
    },
    {
      group_role: 'hysteresis',
      data_type: 'uint16',
      value_format: 'numeric',
      addr_count: 1,
      offset: 4,
      min_value: 0,
      max_value: 65535,
      description: 'Deadband in raw units. 0 for DI/DO sources.',
      visibility_conditions: { 'enabled' => ['1'] }
    },
    {
      group_role: 'logic',
      data_type: 'uint16',
      value_format: 'enum',
      addr_count: 1,
      offset: 5,
      min_value: 0,
      max_value: 1,
      enum_values: LOGIC_ENUM,
      description: 'How to combine with previous condition(s). Ignored on condition 1.',
      visibility_conditions: { 'enabled' => ['1'] }
    },
    {
      group_role: 'on_error',
      data_type: 'uint16',
      value_format: 'enum',
      addr_count: 1,
      offset: 6,
      min_value: 0,
      max_value: 2,
      enum_values: ERROR_BEHAVIOR_ENUM,
      description: 'Action when source IO health is in error state. Only applies to AI/DI sources.',
      visibility_conditions: { 'enabled' => ['1'] }
    }
  ].freeze

  PLC_VERSION_ID = PlcVersion.first.id

  def create_register(interface, group_name, address_offset, current_position, interface_register_mapping_position, reg)
    group_label = group_name.split('_')
    group_label.shift
    group_label = group_label.join(' ')
    name = "DO#{interface.io_number} Operation Mode #{group_label.titleize} #{reg[:group_role].humanize.titleize}"
    label = "DO#{interface.io_number}_OM_#{group_label.titleize.split(' ').join('_')}_#{reg[:group_role].humanize.titleize.split(' ').join('_')}"

    register_template = RegisterTemplate.create!(
      name: name,
      label: label,
      description: reg[:description],
      address: OM_SENSOR_BASE_ADDRESS + address_offset,
      address_count: reg[:addr_count],
      register_type: 'holding',
      data_type: reg[:data_type],
      byte_order: 'big_endian',
      value_format: reg[:value_format],
      factor: 1.0,
      offset: 0.0,
      category: 'operation_mode_configuration',
      group_name: group_name,
      group_role: reg[:group_role],
      validation_rules: reg[:validation_rules],
      visibility_conditions: reg[:visibility_conditions],
      read_only: false,
      min_value: reg[:min_value],
      max_value: reg[:max_value],
      default_value: 0,
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

  (1..12).each do |n|
    interface = Interface.find_by(communication_type: 'digital_output', io_number: n, plc_version_id: PLC_VERSION_ID)
    interface_register_mapping_position = InterfaceRegisterMapping.where(interface: interface).maximum(:position).to_i + 1

    OM_SENSOR_REGISTERS.each do |reg|
      create_register(interface, 'om_sensor', address_offset, current_position, interface_register_mapping_position, reg)

      address_offset += reg[:addr_count]
      current_position += 1
      interface_register_mapping_position += 1
    end

    OM_SENSOR_WINDOW_REGISTERS.each do |reg|
      create_register(interface, 'om_sensor_window', address_offset, current_position, interface_register_mapping_position, reg)

      address_offset += reg[:addr_count]
      current_position += 1
      interface_register_mapping_position += 1
    end

    (1..CONDITIONS_PER_DO).each do |cond_number|
      group_name = "om_sensor_cond_#{cond_number}"

      SENSOR_CONDITION_REGISTERS.each do |reg|
        create_register(interface, group_name, address_offset, current_position, interface_register_mapping_position, reg)

        address_offset += reg[:addr_count]
        current_position += 1
        interface_register_mapping_position += 1
      end
    end

  end

end
