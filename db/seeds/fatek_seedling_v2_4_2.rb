# Usage:
#   rails runner db/seeds/fatek_seedling_v2_4_2.rb
#
# Seeds:
#   - A new Eliwell FreeAdvance firmware version "V2 with Fatek capability"
#     (relay-host enabled, 4 slots × 1200 holding registers each).
#   - FATEK manufacturer + FBs-20MC model + Fatek peripheral firmware version
#     "Seedling Program v2.4.2".
#   - All ~600 Fatek register templates per the supplier's Registers_242 doc.
#   - Relay mappings on the new Eliwell V2 firmware version pointing to every
#     Fatek register template (read-direction for all, write-direction for
#     writable ones).
#   - ModbusFirmwareCompatibility row linking V2 (host) -> Fatek (peripheral).
#
# Prerequisites:
#   - The existing Eliwell FreeAdvance model and V1 firmware version must
#     already exist (created by db/seeds/eliwell_free_advance_registers.rb).
#   - RegisterTemplate.address uniqueness validation must be scoped by
#     [:modbus_firmware_version_id, :register_type] - see the migration note.
#   - PlcBehaviors::GroupSchemas's program_*_phase_* and program_*_meta
#     entries must have empty required_roles (structural markers only).

ActiveRecord::Base.transaction do
  # ── Find prerequisites ────────────────────────────────────────────────

  eliwell_manufacturer = Manufacturer.find_by!(name: 'Eliwell')
  eliwell_model = eliwell_manufacturer.models.find_by!(
    name: 'FreeAdvance AVC12600/C/L/U/I (AVC126006I500)'
  )
  eliwell_v1 = eliwell_model.modbus_firmware_versions.find_by!(version_code: '1.0')

  # ── Eliwell V2 with Fatek hosting capability ──────────────────────────

  eliwell_v2 = ModbusFirmwareVersion.create!(
    name:                'V2 with Fatek capability',
    version_code:        '2.0',
    behavior_profile:    'standard_v1',
    relay_slot_base:     8964,
    relay_slot_size:     1200,
    relay_max_slots:     4,
    relay_register_type: 'holding',
    relay_read_strategy: 'contiguous',
    is_latest:           false,
    is_supported:        true,
    model:               eliwell_model
  )

  # Inherit V1's interfaces and register templates by cloning.
  # The Eliwell hardware is unchanged; only the host-relay capability is added.
  eliwell_v1.interfaces.find_each do |v1_iface|
    Interface.create!(
      name:                      v1_iface.name,
      communication_type:        v1_iface.communication_type,
      description:               v1_iface.description,
      io_number:                 v1_iface.io_number,
      modbus_firmware_version:   eliwell_v2
    )
  end

  eliwell_v2.copy_registers_from(eliwell_v1)

  # ── FATEK manufacturer and model ──────────────────────────────────────

  fatek_manufacturer = Manufacturer.find_or_create_by!(name: 'FATEK')

  fatek_model = Model.create!(
    name:                'FBs-20MC',
    device_type:         'modbus_device',
    manufacturer:        fatek_manufacturer,
    display_type:        'Programmable Controller',
    supports_modbus_tcp: false,
    supports_modbus_rtu: true
  )

  # ── Fatek peripheral firmware version ─────────────────────────────────

  fatek_firmware = ModbusFirmwareVersion.create!(
    name:         'Seedling Program v2.4.2',
    version_code: '2.4.2',
    is_latest:    true,
    is_supported: true,
    model:        fatek_model
  )

  # ── Default measurement subtype lookups ───────────────────────────────

  ambient_humidity_subtype     = MeasurementSubtype.joins(:measurement_type)
    .find_by!(measurement_types: { name: 'Ambient' }, name: 'Humidity')
  ambient_temperature_subtype  = MeasurementSubtype.joins(:measurement_type)
    .find_by!(measurement_types: { name: 'Ambient' }, name: 'Temperature')
  switch_alarm_subtype         = MeasurementSubtype.joins(:measurement_type)
    .find_by!(measurement_types: { name: 'Switch' }, name: 'Alarm')
  switch_heater_subtype        = MeasurementSubtype.joins(:measurement_type)
    .find_by!(measurement_types: { name: 'Switch' }, name: 'Heater')
  switch_compressor_subtype    = MeasurementSubtype.joins(:measurement_type)
    .find_by!(measurement_types: { name: 'Switch' }, name: 'Compressor')
  switch_pump_subtype          = MeasurementSubtype.joins(:measurement_type)
    .find_by!(measurement_types: { name: 'Switch' }, name: 'Pump')

  # ── Helper for building register template attribute hashes ────────────

  position_counter = 0
  next_position = -> { position_counter += 1 }

  build_register = ->(attrs) {
    {
      register_type:           'holding',
      data_type:               'int16',
      byte_order:              'big_endian',
      value_format:            'numeric',
      address_count:           1,
      factor:                  1.0,
      offset:                  0.0,
      read_only:               false,
      user_visibility:         'visible',
      modbus_firmware_version: fatek_firmware,
      position:                next_position.call
    }.merge(attrs)
  }

  registers = []

  # ── R0–R7: currently active phase setpoints (read-only mirrors) ───────

  current_phase_fields = [
    { addr: 0, name: 'Current phase: Temperature low work limit',  factor: 0.01, unit: '°C' },
    { addr: 1, name: 'Current phase: Temperature high work limit', factor: 0.01, unit: '°C' },
    { addr: 2, name: 'Current phase: Temperature low alarm limit', factor: 0.01, unit: '°C' },
    { addr: 3, name: 'Current phase: Temperature high alarm limit', factor: 0.01, unit: '°C' },
    { addr: 4, name: 'Current phase: Humidity work limit',          factor: 0.01, unit: '%' },
    { addr: 5, name: 'Current phase: Humidity alarm limit',         factor: 0.01, unit: '%' },
    { addr: 6, name: 'Current phase: Total duration',               factor: 1.0,  unit: 'min' },
    { addr: 7, name: 'Current phase: Last phase mark',              factor: 1.0,  unit: nil, value_format: 'boolean' }
  ]
  current_phase_fields.each do |f|
    registers << build_register.call(
      name: f[:name], label: "current_phase_#{f[:addr]}",
      address: f[:addr], factor: f[:factor],
      value_format: f[:value_format] || 'numeric',
      category: 'program_status', read_only: true
    )
  end

  # ── R10: active phase number (writable, runtime control) ──────────────

  registers << build_register.call(
    name: 'Active phase number', label: 'active_phase_number',
    address: 10, category: 'configuration',
    group_name: 'program_runtime', group_role: 'active_phase',
    min_value: 0, max_value: 14
  )

  # ── R12: displaying phase number (read-only) ──────────────────────────

  registers << build_register.call(
    name: 'Displaying phase number', label: 'displaying_phase_number',
    address: 12, category: 'program_status', read_only: true
  )

  # ── R15–R17: program version (read-only firmware metadata) ────────────

  [
    [15, 'major', 'Program major version'],
    [16, 'minor', 'Program minor version'],
    [17, 'sub',   'Program subversion']
  ].each do |addr, role, name|
    registers << build_register.call(
      name: name, label: "program_version_#{role}",
      address: addr, category: 'diagnostic', read_only: true
    )
  end

  # ── R25–R28: hysteresis values ────────────────────────────────────────

  hysteresis_fields = [
    { addr: 25, role: 'humidity_work_hysteresis',  name: 'Humidity work limit hysteresis',   factor: 0.01, unit: '%' },
    { addr: 26, role: 'humidity_alarm_hysteresis', name: 'Humidity alarm limit hysteresis',  factor: 0.01, unit: '%' },
    { addr: 27, role: 'temp_work_hysteresis',      name: 'Temperature work limits hysteresis', factor: 0.01, unit: '°C' },
    { addr: 28, role: 'temp_alarm_hysteresis',     name: 'Temperature alarm limits hysteresis', factor: 0.01, unit: '°C' }
  ]
  hysteresis_fields.each do |f|
    registers << build_register.call(
      name: f[:name], label: f[:role],
      address: f[:addr], factor: f[:factor],
      category: 'configuration',
      group_name: 'system_hysteresis', group_role: f[:role]
    )
  end

  # ── R30–R37: delays and timer setpoints ───────────────────────────────

  delay_fields = [
    { addr: 30, role: 'heating_on_delay',         name: 'Heating ON delay',         factor: 0.1, unit: 's' },
    { addr: 31, role: 'cooling_on_delay',         name: 'Cooling ON delay',         factor: 0.1, unit: 's' },
    { addr: 32, role: 'wetting_on_delay',         name: 'Wetting ON delay',         factor: 0.1, unit: 's' },
    { addr: 33, role: 'wetting_off_delay',        name: 'Wetting OFF delay',        factor: 0.1, unit: 's' },
    { addr: 34, role: 'temp_low_alarm_delay',     name: 'Low temperature alarm delay',  factor: 0.1, unit: 's' },
    { addr: 35, role: 'temp_high_alarm_delay',    name: 'High temperature alarm delay', factor: 0.1, unit: 's' },
    { addr: 36, role: 'humidity_low_alarm_delay', name: 'Low humidity alarm delay',     factor: 0.1, unit: 's' },
    { addr: 37, role: 'wetting_timer_seconds',    name: 'Wetting time in timer mode',   factor: 1.0, unit: 's' }
  ]
  delay_fields.each do |f|
    registers << build_register.call(
      name: f[:name], label: f[:role],
      address: f[:addr], factor: f[:factor],
      category: 'configuration',
      group_name: 'system_delays', group_role: f[:role]
    )
  end

  # ── R38: misc constant ────────────────────────────────────────────────

  registers << build_register.call(
    name: 'Constant 1 (MT6050i)', label: 'constant_1',
    address: 38, category: 'configuration',
    group_name: 'system_misc', group_role: 'constant_1'
  )

  # ── R40–R41: sensor offsets ───────────────────────────────────────────

  registers << build_register.call(
    name: 'Humidity sensor offset', label: 'humidity_sensor_offset',
    address: 40, factor: 0.01,
    category: 'configuration',
    group_name: 'system_offsets', group_role: 'humidity_sensor_offset'
  )
  registers << build_register.call(
    name: 'Temperature sensor offset', label: 'temp_sensor_offset',
    address: 41, factor: 0.01,
    category: 'configuration',
    group_name: 'system_offsets', group_role: 'temp_sensor_offset'
  )

  # ── R44–R49: command codes (R44 read-only mark, R45–R49 codes) ────────

  registers << build_register.call(
    name: 'Command codes loaded mark', label: 'command_codes_loaded_mark',
    address: 44, category: 'diagnostic', read_only: true
  )

  command_code_fields = [
    [45, 'start_code',            'Start command code'],
    [46, 'reset_code',            'Reset command code'],
    [47, 'confirm_code',          'Confirm command code'],
    [48, 'stop_code',             'Stop command code'],
    [49, 'copy_setpoints_code',   'Copy setpoints to file area command code']
  ]
  command_code_fields.each do |addr, role, name|
    registers << build_register.call(
      name: name, label: role,
      address: addr, category: 'configuration',
      group_name: 'system_commands', group_role: role
    )
  end

  # ── R50–R55: reference points (internal, hidden) ──────────────────────

  reference_point_fields = [
    [50, 'twl', 'Reference point TWL'],
    [51, 'twh', 'Reference point TWH'],
    [52, 'tal', 'Reference point TAL'],
    [53, 'tah', 'Reference point TAH'],
    [54, 'hw',  'Reference point HW'],
    [55, 'ha',  'Reference point HA']
  ]
  reference_point_fields.each do |addr, suffix, name|
    registers << build_register.call(
      name: name, label: "reference_point_#{suffix}",
      address: addr, category: 'diagnostic',
      read_only: true, user_visibility: 'hidden'
    )
  end

  # ── R60–R61: program runtime state ────────────────────────────────────

  registers << build_register.call(
    name: 'Active program number', label: 'active_program_number',
    address: 60, category: 'configuration',
    group_name: 'program_runtime', group_role: 'active_program',
    min_value: 0, max_value: 3
  )
  registers << build_register.call(
    name: 'Adjusted record number', label: 'adjusted_record_number',
    address: 61, category: 'diagnostic', read_only: true
  )

  # ── R3000–R3007: scaled measurements + runtime copies ─────────────────

  registers << build_register.call(
    name: 'Scaled humidity', label: 'scaled_humidity',
    address: 3000, factor: 0.1,
    category: 'analog', read_only: true,
    default_measurement_subtype: ambient_humidity_subtype
  )
  registers << build_register.call(
    name: 'Scaled temperature', label: 'scaled_temperature',
    address: 3001, factor: 0.1,
    category: 'analog', read_only: true,
    default_measurement_subtype: ambient_temperature_subtype
  )

  runtime_copy_fields = [
    [3002, 'elapsed_time_copy',          'Copy of elapsed phase time'],
    [3003, 'phase_duration_copy',        'Copy of total current phase duration'],
    [3004, 'current_phase_number_copy',  'Copy of current phase number'],
    [3005, 'alarm_code_copy',            'Copy of alarm code'],
    [3006, 'current_program_number_copy', 'Copy of current program number'],
    [3007, 'process_finished_mark',      'Process finished mark']
  ]
  runtime_copy_fields.each do |addr, role, name|
    registers << build_register.call(
      name: name, label: role,
      address: addr, category: 'program_status', read_only: true
    )
  end

  # ── R3010: external command code (writable trigger) ───────────────────

  registers << build_register.call(
    name: 'External command code', label: 'external_command_code',
    address: 3010, category: 'configuration',
    group_name: 'system_commands', group_role: 'external_command'
  )

  # ── D0 (addr 6000): alarm code ────────────────────────────────────────

  registers << build_register.call(
    name: 'Alarm code', label: 'alarm_code',
    address: 6000, category: 'diagnostic', read_only: true
  )

  # ── T50–T70: internal timers (read-only diagnostics) ──────────────────

  internal_timer_fields = [
    [9050, 'timer_reset_delay',          'Reset delay timer'],
    [9051, 'timer_minute',               'Minute timer'],
    [9052, 'timer_heating_delay',        'Heating delay timer'],
    [9053, 'timer_cooling_delay',        'Cooling delay timer'],
    [9054, 'timer_temp_low_alarm',       'Low temperature alarm delay timer'],
    [9055, 'timer_temp_high_alarm',      'High temperature alarm delay timer'],
    [9056, 'timer_wetting_on',           'Wetting ON delay timer'],
    [9057, 'timer_wetting_alarm',        'Wetting alarm delay timer'],
    [9058, 'timer_wetting_off',          'Wetting OFF delay timer'],
    [9060, 'timer_start_delay',          'Start delay timer'],
    [9061, 'timer_blink_period',         'Blink period timer'],
    [9062, 'timer_humidity_control',     'Humidity control ON/OFF delay timer'],
    [9070, 'timer_external_command_reset', 'External command reset delay timer']
  ]
  internal_timer_fields.each do |addr, role, name|
    registers << build_register.call(
      name: name, label: role,
      address: addr, category: 'diagnostic',
      read_only: true, user_visibility: 'hidden'
    )
  end

  # ── T200–T201: wetting timer mode (writable config) ──────────────────

  registers << build_register.call(
    name: 'Wetting ON timer (timer mode)', label: 'wetting_on_timer',
    address: 9200, category: 'configuration',
    group_name: 'system_delays', group_role: 'wetting_on_timer_mode'
  )
  registers << build_register.call(
    name: 'Wetting OFF timer (timer mode)', label: 'wetting_off_timer',
    address: 9201, category: 'configuration',
    group_name: 'system_delays', group_role: 'wetting_off_timer_mode'
  )

  # ── C0: current phase elapsed time counter ────────────────────────────

  registers << build_register.call(
    name: 'Current phase elapsed time', label: 'current_phase_elapsed_time',
    address: 9500, category: 'program_status', read_only: true
  )

  # ── Programs block (R5000–R5510): 4 programs × 15 phases × 8 fields ───
  #
  # Address layout:
  #   Program 0: phase N starts at 5000 + (N-1)*8
  #   Program M (M≥1): phase N starts at 5128 + (M-1)*128 + (N-1)*8
  #   Program meta: humidity_control_mode at base+124, loaded_mark at base+126
  #   Program 0 has no loaded_mark register.

  PROGRAM_BASES = {
    0 => 5000,
    1 => 5128,
    2 => 5256,
    3 => 5384
  }.freeze

  PHASE_FIELD_DEFS = [
    { offset: 0, role: 'temp_low_work',     name: 'Temperature Low Work Limit',   factor: 0.01, unit: '°C' },
    { offset: 1, role: 'temp_high_work',    name: 'Temperature High Work Limit',  factor: 0.01, unit: '°C' },
    { offset: 2, role: 'temp_low_alarm',    name: 'Temperature Low Alarm Limit',  factor: 0.01, unit: '°C' },
    { offset: 3, role: 'temp_high_alarm',   name: 'Temperature High Alarm Limit', factor: 0.01, unit: '°C' },
    { offset: 4, role: 'humidity_work',     name: 'Humidity Work Limit',          factor: 0.01, unit: '%' },
    { offset: 5, role: 'humidity_alarm',    name: 'Humidity Alarm Limit',         factor: 0.01, unit: '%' },
    { offset: 6, role: 'duration_minutes',  name: 'Duration',                     factor: 1.0,  unit: 'min', value_format: 'numeric' },
    { offset: 7, role: 'is_last_phase',     name: 'Last Phase Mark',              factor: 1.0,  unit: nil,   value_format: 'boolean' }
  ].freeze

  PROGRAM_BASES.each do |program_idx, base_addr|
    (1..15).each do |phase_idx|
      phase_base = if program_idx == 0
        base_addr + (phase_idx - 1) * 8
      else
        base_addr + (phase_idx - 1) * 8
      end

      PHASE_FIELD_DEFS.each do |fd|
        registers << build_register.call(
          name:         fd[:name],
          label:        "program_#{program_idx}_phase_#{phase_idx}_#{fd[:role]}",
          address:      phase_base + fd[:offset],
          factor:       fd[:factor],
          value_format: fd[:value_format] || 'numeric',
          category:     'program_configuration',
          group_name:   "program_#{program_idx}_phase_#{phase_idx}",
          group_role:   fd[:role]
        )
      end
    end

    # Program meta: humidity_control_mode for all 4, loaded_mark for 1-3
    humidity_addr = base_addr + 124
    registers << build_register.call(
      name:         "Humidity Control Mode",
      label:        "program_#{program_idx}_humidity_control_mode",
      address:      humidity_addr,
      value_format: 'boolean',
      category:     'program_configuration',
      group_name:   "program_#{program_idx}_meta",
      group_role:   'humidity_control_mode'
    )

    if program_idx > 0
      loaded_mark_addr = base_addr + 126
      registers << build_register.call(
        name:        "Loaded Mark",
        label:       "program_#{program_idx}_loaded_mark",
        address:     loaded_mark_addr,
        category:    'program_status',
        group_name:  "program_#{program_idx}_meta",
        group_role:  'loaded_mark',
        read_only:   true
      )
    end
  end

  # ── R5512: local program selecting allowed/denied ─────────────────────

  registers << build_register.call(
    name: 'Local program selecting allowed', label: 'local_program_selecting_allowed',
    address: 5512, value_format: 'boolean',
    category: 'configuration',
    group_name: 'system_misc', group_role: 'local_program_selecting_allowed'
  )

  # ── Y0–Y8: digital outputs (status data, read-only from FarmBits) ─────
  #
  # Driven by Fatek's program engine. read_only=true so users monitor
  # without competing with the program logic.

  y_outputs = [
    { addr: 0, name: 'Process lamp',                    subtype: nil },
    { addr: 1, name: 'Alarm lamp',                      subtype: switch_alarm_subtype },
    { addr: 2, name: 'Heating output',                  subtype: switch_heater_subtype },
    { addr: 3, name: 'Cooling output',                  subtype: switch_compressor_subtype },
    { addr: 4, name: 'Wetting output',                  subtype: switch_pump_subtype },
    { addr: 5, name: 'Buzzer',                          subtype: nil },
    { addr: 6, name: 'Finish lamp',                     subtype: nil },
    { addr: 7, name: 'Humidity control by timer lamp',  subtype: nil },
    { addr: 8, name: 'Humidity control disabled',       subtype: nil }
  ]
  y_outputs.each do |y|
    registers << build_register.call(
      name:                        y[:name],
      label:                       "y#{y[:addr]}_#{y[:name].downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '')}",
      address:                     y[:addr],
      register_type:               'coil',
      data_type:                   'boolean',
      value_format:                'boolean',
      category:                    'status',
      read_only:                   true,
      default_measurement_subtype: y[:subtype]
    )
  end

  # ── X0–X7: physical button inputs (diagnostic, read-only) ─────────────

  x_inputs = [
    { addr: 1000, name: 'Start button (physical)' },
    { addr: 1001, name: 'Reset button (physical)' },
    { addr: 1002, name: 'Confirm button (physical)' },
    { addr: 1003, name: 'Stop button (physical)' },
    { addr: 1004, name: 'Humidity control switch (physical)' },
    { addr: 1005, name: 'Manual sprinkling button (physical)' },
    { addr: 1007, name: 'Operating voltage present' }
  ]
  x_inputs.each_with_index do |x, idx|
    label_addr = x[:addr] - 1000
    registers << build_register.call(
      name:            x[:name],
      label:           "x#{label_addr}_#{x[:name].downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '')}",
      address:         x[:addr],
      register_type:   'coil',
      data_type:       'boolean',
      value_format:    'boolean',
      category:        'diagnostic',
      read_only:       true,
      user_visibility: 'hidden'
    )
  end

  # ── M-bits: memory bits (state flags + writable command bits) ─────────

  # State flags - read-only from FarmBits perspective
  m_state_flags = [
    [2000, 'Process'],
    [2001, 'Confirmed'],
    [2010, 'No operating voltage'],
    [2011, 'Error copying setpoints to file'],
    [2012, 'Setpoints copied to file'],
    [2013, 'Program changing allowed'],
    [2014, 'Program 0 selected'],
    [2015, 'All programs loaded'],
    [2016, 'Program does not exist'],
    [2017, 'Incorrect humidity data'],
    [2018, 'Incorrect temperature data'],
    [2020, 'Current phase finished'],
    [2049, 'Manual sprinkling activated'],
    [2050, 'Reset executing command'],
    [2051, 'One more minute'],
    [2052, 'Heating executing command'],
    [2053, 'Cooling executing command'],
    [2054, 'Low temperature alarm'],
    [2055, 'High temperature alarm'],
    [2056, 'Wetting ON executing command'],
    [2057, 'Low humidity alarm'],
    [2058, 'Wetting OFF executing command'],
    [2059, 'Humidity control ON/OFF executing command'],
    [2060, 'Start executing command'],
    [2061, 'Blink bit'],
    [2062, 'Auxiliary blink bit'],
    [2063, 'Alarm conditions'],
    [2064, 'Prepare data for new phase'],
    [2065, 'Process finished'],
    [2800, 'Process memorization']
  ]
  m_state_flags.each do |addr, name|
    label_addr = addr - 2000
    registers << build_register.call(
      name:            name,
      label:           "m#{label_addr}_#{name.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '')}",
      address:         addr,
      register_type:   'coil',
      data_type:       'boolean',
      value_format:    'boolean',
      category:        'diagnostic',
      read_only:       true,
      user_visibility: 'hidden'
    )
  end

  # Writable command bits - on-screen and external command triggers
  m_command_bits = [
    [2030, 'cmd_start_screen',           'Start (on-screen)'],
    [2031, 'cmd_reset_screen',           'Reset (on-screen)'],
    [2032, 'cmd_confirm_screen',         'Confirm (on-screen)'],
    [2033, 'cmd_stop_screen',            'Stop (on-screen)'],
    [2036, 'cmd_manual_heating',         'Manual heating (on-screen)'],
    [2037, 'cmd_manual_cooling',         'Manual cooling (on-screen)'],
    [2038, 'cmd_manual_sprinkling',      'Manual sprinkling (on-screen)'],
    [2040, 'cmd_start_external',         'Start (external)'],
    [2041, 'cmd_reset_external',         'Reset (external)'],
    [2042, 'cmd_confirm_external',       'Confirm (external)'],
    [2043, 'cmd_stop_external',          'Stop (external)'],
    [2044, 'cmd_copy_setpoints_external', 'Copy setpoints (external)'],
    [2045, 'cmd_read_phase_sp',          'Read phase SP (external)'],
    [2046, 'cmd_humidity_control_mode',  'Humidity control mode'],
    [2047, 'cmd_humidity_control_off',   'Humidity control OFF']
  ]
  m_command_bits.each do |addr, role, name|
    label_addr = addr - 2000
    registers << build_register.call(
      name:          name,
      label:         "m#{label_addr}_#{role}",
      address:       addr,
      register_type: 'coil',
      data_type:     'boolean',
      value_format:  'boolean',
      category:      'configuration',
      group_name:    'system_commands',
      group_role:    role
    )
  end

  # ── Bulk insert all register templates ────────────────────────────────

  RegisterTemplate.create!(registers)

  # ── Relay mappings on Eliwell V2 pointing at every Fatek register ─────
  #
  # Layout (within each 1200-register slot):
  #   Reads:  offsets 0..N-1, sequential by register address ascending
  #   Writes: offsets 600..600+M-1, sequential by register address ascending
  #
  # Adjust this layout if your Eliwell V2 firmware has a different
  # mirroring scheme.

  # Layout: reads at offsets 0..N-1, writes at WRITE_BASE_OFFSET..M.
  # Fatek currently has 617 read mappings and 525 write mappings;
  # WRITE_BASE_OFFSET=650 leaves a small gap above reads and fits both
  # blocks in the 1200-register slot. Tune if your Eliwell V2 firmware
  # uses a different mirror scheme.
  READ_BASE_OFFSET  = 0
  WRITE_BASE_OFFSET = 650

  fatek_registers = fatek_firmware.register_templates.order(:address)
  read_mappings = []
  write_mappings = []

  fatek_registers.each_with_index do |rt, read_index|
    read_mappings << {
      modbus_firmware_version_id: eliwell_v2.id,
      register_template_id:       rt.id,
      relay_offset:               READ_BASE_OFFSET + read_index,
      direction:                  'read'
    }
  end

  writable_index = 0
  fatek_registers.each do |rt|
    if rt.read_only?
      next
    end

    write_mappings << {
      modbus_firmware_version_id: eliwell_v2.id,
      register_template_id:       rt.id,
      relay_offset:               WRITE_BASE_OFFSET + writable_index,
      direction:                  'write'
    }
    writable_index += 1
  end

  ModbusFirmwareRelayMapping.insert_all!(
    read_mappings.map { |m| m.merge(created_at: Time.current, updated_at: Time.current) }
  )
  ModbusFirmwareRelayMapping.insert_all!(
    write_mappings.map { |m| m.merge(created_at: Time.current, updated_at: Time.current) }
  )

  # ── Validate slot capacity ────────────────────────────────────────────

  total_read_offsets  = read_mappings.size
  total_write_offsets = write_mappings.size
  max_read_offset     = READ_BASE_OFFSET + total_read_offsets - 1
  max_write_offset    = WRITE_BASE_OFFSET + total_write_offsets - 1
  highest_offset      = [max_read_offset, max_write_offset].max

  if highest_offset >= eliwell_v2.relay_slot_size
    raise "Relay layout exceeds slot size (#{eliwell_v2.relay_slot_size}): " \
          "highest offset is #{highest_offset}"
  end

  if WRITE_BASE_OFFSET < total_read_offsets
    raise "Read block (#{total_read_offsets} offsets) overlaps write base " \
          "(#{WRITE_BASE_OFFSET}); choose a higher WRITE_BASE_OFFSET"
  end

  # ── Compatibility row: Eliwell V2 (host) ↔ Fatek (peripheral) ─────────

  ModbusFirmwareCompatibility.create!(
    host_version:       eliwell_v2,
    peripheral_version: fatek_firmware,
    firmware_code:      1
  )

  Rails.logger.info <<~SUMMARY
    [Fatek seed] Done.
      Eliwell V2 firmware version id: #{eliwell_v2.id}
      Fatek peripheral firmware version id: #{fatek_firmware.id}
      Register templates: #{fatek_registers.count}
      Read relay mappings: #{total_read_offsets}
      Write relay mappings: #{total_write_offsets}
      Highest relay offset: #{highest_offset} / #{eliwell_v2.relay_slot_size}
  SUMMARY
end
