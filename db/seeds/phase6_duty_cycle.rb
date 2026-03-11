# Creates RegisterTemplates, InterfaceRegisterMappings
# for duty cycle and duty cycle time window on digital_output interfaces.
#
# Per DO:
#   om_duty_cycle        - Enable, ON/OFF/total durations (4 registers, 7 addresses)
#   om_duty_cycle_window - Optional time window with sunrise/sunset (6 registers, 6 addresses)
#
# NOTE: Replace base addresses with actual Modbus addresses from PLC firmware.
#
# Usage:
#   rails runner db/seeds/phase6_duty_cycle.rb
#

ActiveRecord::Base.transaction do
  OM_DUTY_CYCLE_BASE_ADDRESS = 17286

  OM_DUTY_CYCLE_REGISTERS = [
    {
      group_role: 'enabled',
      data_type: 'boolean',
      value_format: 'boolean',
      addr_count: 1,
      offset: 0,
      description: 'Master toggle. Preserves all config when OFF.'
    },
    {
      group_role: 'on_duration',
      data_type: 'uint32',
      value_format: 'duration_seconds',
      addr_count: 2,
      offset: 1,
      description: 'ON phase length in seconds. 0 = duty cycle treated as disabled by PLC.',
      validation_rules: {
        'required_when' => { 'group_role' => 'enabled', 'equals' => '1' },
        'greater_than_value' => 0
      }
    },
    {
      group_role: 'off_duration',
      data_type: 'uint32',
      value_format: 'duration_seconds',
      addr_count: 2,
      offset: 3,
      description: 'OFF phase length in seconds. 0 = duty cycle treated as disabled by PLC.',
      validation_rules: {
        'required_when' => { 'group_role' => 'enabled', 'equals' => '1' },
        'greater_than_value' => 0
      }
    },
    {
      group_role: 'total_duration',
      data_type: 'uint32',
      value_format: 'duration_seconds',
      addr_count: 2,
      offset: 5,
      description: 'Total run time in seconds. 0 = continuous (no limit).'
    }
  ].freeze

  OM_DUTY_CYCLE_WINDOW_REGISTERS = [
    {
      group_role: 'start_ref',
      data_type: 'uint16',
      value_format: 'enum',
      addr_count: 1,
      offset: 0,
      min_value: 0,
      max_value: 2,
      enum_values: { '0' => 'fixed', '1' => 'sunrise', '2' => 'sunset' },
      description: 'Time reference for window start.',
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
      description: 'Local minutes (fixed) or signed offset from sunrise/sunset.',
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
      description: 'Time reference for window end.',
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
      description: 'Local minutes (fixed) or signed offset from sunrise/sunset.',
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
      description: 'Day-of-week bitmask. bit0=Sun..bit6=Sat. 0 = no window (always active).',
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
      description: 'Encoded month×100+day (e.g., 315 = March 15). 0 = recurring per days_bitmask.',
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
      address: OM_DUTY_CYCLE_BASE_ADDRESS + address_offset,
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

    OM_DUTY_CYCLE_REGISTERS.each do |reg|
      create_register(interface, 'om_duty_cycle', address_offset, current_position, interface_register_mapping_position, reg)

      address_offset += reg[:addr_count]
      current_position += 1
      interface_register_mapping_position += 1
    end


    OM_DUTY_CYCLE_WINDOW_REGISTERS.each do |reg|
      create_register(interface, 'om_duty_cycle_window', address_offset, current_position, interface_register_mapping_position, reg)

      address_offset += reg[:addr_count]
      current_position += 1
      interface_register_mapping_position += 1
    end
  end

end
