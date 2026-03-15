# Creates RegisterTemplates, InterfaceRegisterMappings
# for schedule slots on digital_output interfaces.
#
# Each DO gets 6 independent schedule slots (om_schedule_1..om_schedule_6).
# Each slot has 7 registers (8 Modbus addresses due to uint32 duration).
#
# Slot types:
#   Recurring weekly: days_bitmask > 0, onetime_month = 0
#   One-time event:   onetime_year > 0, onetime_month > 0, onetime_day > 0
#   Disabled:         days_bitmask = 0 AND onetime_month = 0
#
# Start time supports sunrise/sunset offsets via start_ref:
#   0 = fixed (start_time is absolute local minutes since midnight)
#   1 = sunrise (start_time is signed offset from sunrise_minutes)
#   2 = sunset (start_time is signed offset from sunset_minutes)
#
#
# Usage:
#   rails runner db/seeds/phase5_schedule_slots.rb
#

ActiveRecord::Base.transaction do
  OM_SCHEDULE_BASE_ADDRESS = 16710

  # ============================================================
  # Register definitions (same for all 6 slots)
  # ============================================================

  SCHEDULE_SLOT_REGISTERS = [
    {
      group_role: 'enabled',
      data_type: 'boolean',
      value_format: 'boolean',
      addr_count: 1,
      offset: 0,
      description: 'Master toggle. Preserves all config when OFF.'
    },
    {
      group_role: 'start_ref',
      data_type: 'uint16',
      value_format: 'enum',
      addr_count: 1,
      offset: 0,
      default_value: 0,
      min_value: 0,
      max_value: 2,
      enum_values: { '0' => 'fixed', '1' => 'sunrise', '2' => 'sunset' },
      description: 'Time reference for start. Fixed = absolute minutes, sunrise/sunset = offset from sun event.'
    },
    {
      group_role: 'start_time',
      data_type: 'int16',
      value_format: 'numeric',
      addr_count: 1,
      offset: 1,
      default_value: 0,
      min_value: -1439,
      max_value: 1439,
      description: 'Local minutes-since-midnight (fixed) or signed offset from sunrise/sunset.'
    },
    {
      group_role: 'duration',
      data_type: 'uint32',
      value_format: 'duration_seconds',
      addr_count: 2,
      offset: 2,
      default_value: 0,
      min_value: 0,
      description: 'How long to keep ON in seconds. 0 = slot disabled. No upper limit (uint32).',
      validation_rules: {
        'required_when_any' => [
          { 'group_role' => 'days', 'not_equals' => '0' },
          { 'group_role' => 'onetime_month', 'not_equals' => '0' }
        ]
      }
    },
    {
      group_role: 'days',
      data_type: 'uint16',
      value_format: 'bitmask',
      addr_count: 1,
      offset: 4,
      default_value: 0,
      min_value: 0,
      max_value: 127,
      description: 'Day-of-week bitmask. bit0=Sun..bit6=Sat. 0 = disabled (unless onetime set).',
      enum_values: {
        '0' => 'Sun', '1' => 'Mon', '2' => 'Tue', '3' => 'Wed',
        '4' => 'Thu', '5' => 'Fri', '6' => 'Sat'
      }
    },
    {
      group_role: 'onetime_month',
      data_type: 'uint16',
      value_format: 'numeric',
      addr_count: 1,
      offset: 5,
      default_value: 0,
      min_value: 0,
      max_value: 12,
      description: '0 = recurring per days_bitmask. 1-12 = one-time event month.'
    },
    {
      group_role: 'onetime_day',
      data_type: 'uint16',
      value_format: 'numeric',
      addr_count: 1,
      offset: 6,
      default_value: 0,
      min_value: 0,
      max_value: 31,
      description: '0 = recurring. 1-31 = one-time event day.',
      validation_rules: {
        'required_when' => { 'group_role' => 'onetime_month', 'not_equals' => '0' }
      }
    },
    {
      group_role: 'onetime_year',
      data_type: 'uint16',
      value_format: 'numeric',
      addr_count: 1,
      offset: 7,
      default_value: 0,
      min_value: 0,
      max_value: 9999,
      description: '0 = recurring. Year of one-time event (e.g., 2026). Used by backend for cleanup. PLC ignores.',
      validation_rules: {
        'required_when' => { 'group_role' => 'onetime_month', 'not_equals' => '0' }
      }
    }
  ].freeze

  PLC_VERSION_ID = PlcVersion.first.id

  def create_register(interface, slot_number, address_offset, current_position, interface_register_mapping_position, reg)
    group_name = "om_schedule_#{slot_number}"
    name = "DO#{interface.io_number} Operation Mode Schedule #{slot_number} #{reg[:group_role].humanize.titleize}"
    label = "DO#{interface.io_number}_OM_Schedule_#{slot_number}_#{reg[:group_role].humanize.titleize.split(' ').join('_')}"

    register_template = RegisterTemplate.create!(
      name: name,
      label: label,
      description: reg[:description],
      address: OM_SCHEDULE_BASE_ADDRESS + address_offset,
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
      read_only: false,
      user_visibility: 'visible',
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

    (1..6).each do |slot_number|
      SCHEDULE_SLOT_REGISTERS.each do |reg|
        create_register(interface, slot_number, address_offset, current_position, interface_register_mapping_position, reg)

        address_offset += reg[:addr_count]
        current_position += 1
        interface_register_mapping_position += 1
      end
    end
  end

end
