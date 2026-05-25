# Usage:
#   rails runner db/seeds/fatek_seedling_v2_4_2.rb
#

ActiveRecord::Base.transaction do

  # ╭──────────────────────────────────────────────────────────────────────╮
  # │ Eliwell V2 (Fatek bridge) + Fatek FBs-20MC Seedling Program v2.4.2   │
  # │                                                                      │
  # │ Eliwell V2 is a bridge-only firmware — no behavior_profile, no       │
  # │ system groups beyond what's needed to host Fatek peripherals.        │
  # │                                                                      │
  # │ Slot layout (1200 holding registers per slot):                       │
  # │   READ MIRROR  (offsets 0..649)                                      │
  # │     0..7    R0..R7         active phase set points (RO)              │
  # │     8..15   R3000..R3007   live data x10sec (RO)                     │
  # │     16..33  system status mix (R10, R12, R15-R17, R44, R60, R61,     │
  # │                              R3010, R5512, R5124, R5252, R5380,      │
  # │                              R5508, D0, R5254, R5382, R5510)         │
  # │     40..56  R25..R41       parameters (gaps at R29/R39 preserved)    │
  # │     60..179   R5000..R5119  program 0 phases                         │
  # │     180..299  R5128..R5247  program 1 phases                         │
  # │     300..419  R5256..R5375  program 2 phases                         │
  # │     420..539  R5384..R5503  program 3 phases                         │
  # │     540..556  T50..C0       timers + counter                         │
  # │     560..568  Y0..Y8        coil outputs (mirrored)                  │
  # │     570..614  M-bits        memory bits (RO + RW reads)              │
  # │     620..626  X0..X7        physical inputs (discrete mirrored)      │
  # │                                                                      │
  # │   WRITE BUFFER (offsets 650..1199)                                   │
  # │     650..664  R25..R41      parameters writes (packed)               │
  # │     665..669  R45..R49      command buttons (write-only)             │
  # │     670..677  system status RW writes                                │
  # │     680..799  R5000..R5119  program 0 writes                         │
  # │     800..919  R5128..R5247  program 1 writes                         │
  # │     920..1039 R5256..R5375  program 2 writes                         │
  # │     1040..1159 R5384..R5503 program 3 writes                         │
  # │     1160..1176 T50..C0      timer writes                             │
  # │     1177..1191 M-bits RW    command bit writes                       │
  # ╰──────────────────────────────────────────────────────────────────────╯

  eliwell_manufacturer = Manufacturer.find_by!(name: 'Eliwell')
  eliwell_model = eliwell_manufacturer.models.find_by!(
    name: 'FreeAdvance AVC12600/C/L/U/I (AVC126006I500)'
  )

  # ── Eliwell V2 — bridge-only firmware for hosting Fatek peripherals ────

  eliwell_v2 = ModbusFirmwareVersion.create!(
    name:                'V2 with Fatek capability',
    version_code:        '2.0',
    address_offset:      -1,
    relay_slot_base:     8968,
    relay_slot_size:     1200,
    relay_max_slots:     4,
    relay_register_type: 'holding',
    relay_read_strategy: 'relay_contiguous',
    is_latest:           false,
    is_supported:        true,
    model:               eliwell_model
  )

  EEPROM_BASE      = 16384
  COMM_STATUS_BASE = 8960

  # ── SMTP push data registers (EEPROM_BASE + 0..) ───────────────────────

  smtp_push_data_registers = [
    {
      name: 'SMTP Hostname',
      label: 'SMTP_Hostname',
      description: 'SMTP server hostname for push data notifications',
      address_count: 16,
      data_type: 'string',
      value_format: 'ascii_string',
      group_role: 'hostname',
      default_value: 'plc.farm-bits.com'
    },
    {
      name: 'SMTP Port',
      label: 'SMTP_Port',
      description: 'SMTP server port for push data notifications',
      address_count: 1,
      data_type: 'uint16',
      value_format: 'numeric',
      group_role: 'port',
      default_value: 25
    },
    {
      name: 'SMTP Username',
      label: 'SMTP_Username',
      description: 'SMTP server username for push data notifications',
      address_count: 16,
      data_type: 'string',
      value_format: 'ascii_string',
      group_role: 'username'
    },
    {
      name: 'SMTP Password',
      label: 'SMTP_Password',
      description: 'SMTP server password for push data notifications',
      address_count: 16,
      data_type: 'string',
      value_format: 'ascii_string',
      group_role: 'password'
    },
    {
      name: 'SMTP To Email',
      label: 'SMTP_To_Email',
      description: 'Destination email address for push data notifications',
      address_count: 16,
      data_type: 'string',
      value_format: 'ascii_string',
      group_role: 'to_email',
      default_value: 'data@plc.farm-bits.com'
    }
  ]

  smtp_offset = 0
  eliwell_v2_register_position = 1

  smtp_push_data_registers.each do |attrs|
    RegisterTemplate.create!(attrs.merge(
      modbus_firmware_version:  eliwell_v2,
      register_type:            'holding',
      byte_order:               'big_endian',
      factor:                   1.0,
      offset:                   0.0,
      category:                 'configuration',
      group_name:               'smtp_push_data',
      read_only:                false,
      user_visibility:          'hidden',
      address:                  EEPROM_BASE + smtp_offset,
      bulk_read_group:          'smtp_push_data',
      bulk_read_address:        EEPROM_BASE,
      bulk_read_offset:         smtp_offset,
      position:                 eliwell_v2_register_position
    ))

    smtp_offset += attrs[:address_count]
    eliwell_v2_register_position += 1
  end

  # ── Per-slot slave_id config (EEPROM_BASE + 65..) ──────────────────────

  slot_config_offset_base = smtp_offset

  eliwell_v2.relay_max_slots.times do |slot|
    group_name  = "ext_device_#{slot + 1}"
    slot_offset = slot_config_offset_base + slot

    RegisterTemplate.create!(
      name:                    "Slot #{slot + 1} Slave ID",
      label:                   "FatekSlot#{slot + 1}_SlaveId",
      description:             "Peripheral Modbus slave_id for slot #{slot + 1}.",
      address:                 EEPROM_BASE + slot_offset,
      address_count:           1,
      register_type:           'holding',
      data_type:               'uint16',
      byte_order:              'big_endian',
      value_format:            'numeric',
      factor:                  1.0,
      offset:                  0.0,
      category:                'configuration',
      group_name:              group_name,
      group_role:              'slave_id',
      bulk_read_group:         'ext_device_config',
      bulk_read_address:       EEPROM_BASE,
      bulk_read_offset:        slot_offset,
      read_only:               false,
      user_visibility:         'hidden',
      min_value:               0,
      max_value:               247,
      default_value:           0,
      position:                eliwell_v2_register_position,
      modbus_firmware_version: eliwell_v2
    )
    eliwell_v2_register_position += 1
  end

  # ── Per-slot comm status diagnostics (COMM_STATUS_BASE + 0..) ──────────

  eliwell_v2.relay_max_slots.times do |slot|
    group_name = "ext_device_#{slot + 1}"

    RegisterTemplate.create!(
      name:                    "Slot #{slot + 1} Comm Status",
      label:                   "FatekSlot#{slot + 1}_CommStatus",
      description:             "Host-synthesized communication status for slot #{slot + 1}.",
      address:                 COMM_STATUS_BASE + slot,
      address_count:           1,
      register_type:           'holding',
      data_type:               'uint16',
      byte_order:              'big_endian',
      value_format:            'enum',
      factor:                  1.0,
      offset:                  0.0,
      category:                'diagnostic',
      group_name:              group_name,
      group_role:              'comm_status',
      bulk_read_group:         'ext_device_status',
      bulk_read_address:       COMM_STATUS_BASE,
      bulk_read_offset:        slot,
      read_only:               true,
      user_visibility:         'visible',
      enum_values: {
        '0' => 'OK',
        '1' => 'Timeout reached',
        '2' => 'Modbus exception'
      },
      position:                eliwell_v2_register_position,
      modbus_firmware_version: eliwell_v2
    )
    eliwell_v2_register_position += 1
  end

  # ── Per-slot refresh programs ─────────────────────────

  eliwell_v2.relay_max_slots.times do |slot|
    group_name = "ext_device_#{slot + 1}"

    RegisterTemplate.create!(
      name:                    "Slot #{slot + 1} Refresh Programs",
      label:                   "FatekSlot#{slot + 1}_RefreshPrograms",
      description:             "Bitmask trigger: set bit N to refresh program N from peripheral.",
      address:                 8964 + slot,
      address_count:           1,
      register_type:           'holding',
      data_type:               'uint16',
      byte_order:              'big_endian',
      value_format:            'bitmask',
      factor:                  1.0,
      offset:                  0.0,
      category:                'configuration',
      group_name:              group_name,
      group_role:              'refresh_programs',
      bulk_read_group:         'ext_device_refresh_triggers',
      bulk_read_address:       8964,
      bulk_read_offset:        slot,
      read_only:               false,
      user_visibility:         'hidden',
      enum_values: {
        '0' => 'Program 1',
        '1' => 'Program 2',
        '2' => 'Program 3',
        '3' => 'Program 4'
      },
      default_value:           0,
      position:                eliwell_v2_register_position,
      modbus_firmware_version: eliwell_v2
    )
    eliwell_v2_register_position += 1
  end

  # ── FATEK manufacturer + model ─────────────────────────────────────────

  fatek_manufacturer = Manufacturer.find_or_create_by!(name: 'FATEK')

  fatek_model = Model.create!(
    name:                'FBs-20MC',
    device_type:         'modbus_device',
    manufacturer:        fatek_manufacturer,
    display_type:        'Programmable Controller',
    supports_modbus_tcp: false,
    supports_modbus_rtu: true
  )

  # ── Fatek peripheral firmware version ──────────────────────────────────

  fatek_firmware = ModbusFirmwareVersion.create!(
    name:           'Seedling Program v2.4.2',
    version_code:   '2.4.2',
    address_offset: 1,
    is_latest:      true,
    is_supported:   true,
    model:          fatek_model
  )

  # ── Compatibility: Eliwell V2 hosts Fatek Seedling Program v2.4.2 ──────

  ModbusFirmwareCompatibility.create!(
    host_version:       eliwell_v2,
    peripheral_version: fatek_firmware,
    firmware_code:      1
  )

  # ── Measurement subtype lookup (tolerant of missing names) ─────────────
  #
  # Adjust the names in `subtype_names` below to match the subtypes you
  # already have seeded. Anything not found logs a warning and skips the
  # default_measurement_subtype assignment — the seed continues either way.

  subtype_names = {
    humidity:    'Humidity > Ambient',
    temperature: 'Temperature > Ambient'
  }

  find_subtype = ->(key) do
    name = subtype_names[key]
    if name.nil?
      return nil
    end
    st = MeasurementSubtype.find_by(name: name)
    if st.nil?
      Rails.logger.warn(
        "[Fatek seed] MeasurementSubtype '#{name}' (#{key}) not found; " \
        "default_measurement_subtype will be nil on matching templates"
      )
    end
    st
  end

  humidity_subtype    = find_subtype.call(:humidity)
  temperature_subtype = find_subtype.call(:temperature)

  # ── Helper procs ───────────────────────────────────────────────────────

  fatek_position = 0

  create_fatek_template = ->(attrs) do
    fatek_position += 1
    RegisterTemplate.create!({
      modbus_firmware_version: fatek_firmware,
      byte_order:              'big_endian',
      address_count:           1,
      factor:                  1.0,
      offset:                  0.0,
      user_visibility:         'visible',
      position:                fatek_position
    }.merge(attrs))
  end

  create_relay_mapping = ->(template, direction, offset) do
    ModbusFirmwareRelayMapping.create!(
      modbus_firmware_version: eliwell_v2,
      register_template:       template,
      direction:               direction,
      relay_offset:            offset
    )
  end

  create_fatek_register = ->(attrs, read_offset: nil, write_offset: nil) do
    template = create_fatek_template.call(attrs)
    if read_offset
      create_relay_mapping.call(template, 'read', read_offset)
    end
    if write_offset && !template.read_only?
      create_relay_mapping.call(template, 'write', write_offset)
    end
    template
  end

  # ════════════════════════════════════════════════════════════════════════
  # Block 1: Active phase set points (R0..R7) — RO mirror
  # ════════════════════════════════════════════════════════════════════════

  active_phase_specs = [
    { addr: 0, name: 'Active phase temperature low work limit',   role: 'temp_low_work',   factor: 0.01 },
    { addr: 1, name: 'Active phase temperature high work limit',  role: 'temp_high_work',  factor: 0.01 },
    { addr: 2, name: 'Active phase temperature low alarm limit',  role: 'temp_low_alarm',  factor: 0.01 },
    { addr: 3, name: 'Active phase temperature high alarm limit', role: 'temp_high_alarm', factor: 0.01 },
    { addr: 4, name: 'Active phase humidity work limit',          role: 'humidity_work',   factor: 0.01 },
    { addr: 5, name: 'Active phase humidity alarm limit',         role: 'humidity_alarm',  factor: 0.01 },
    { addr: 6, name: 'Active phase total duration',               role: 'duration',        factor: 1.0  },
    { addr: 7, name: 'Active phase last phase mark',              role: 'last_phase_mark', factor: 1.0  }
  ]

  active_phase_specs.each do |spec|
    create_fatek_register.call(
      {
        name:              spec[:name],
        label:             "ActivePhase_#{spec[:role].split('_').map(&:capitalize).join}",
        address:           spec[:addr],
        register_type:     'holding',
        data_type:         'int16',
        value_format:      'numeric',
        factor:            spec[:factor],
        category:          'diagnostic',
        read_only:         true,
        group_name:        'active_phase',
        group_role:        spec[:role],
        bulk_read_group:   'active_phase',
        bulk_read_address: 0,
        bulk_read_offset:  spec[:addr]
      },
      read_offset: spec[:addr]
    )
  end

  # ════════════════════════════════════════════════════════════════════════
  # Block 2: Live data x10sec (R3000..R3007) — RO measurements
  # ════════════════════════════════════════════════════════════════════════

  live_data_specs = [
    { addr: 3000, name: 'Humidity',                        role: 'humidity',       category: 'analog',     factor: 0.1, data_type: 'int16',  subtype: humidity_subtype },
    { addr: 3001, name: 'Temperature',                     role: 'temperature',    category: 'analog',     factor: 0.1, data_type: 'int16',  subtype: temperature_subtype },
    { addr: 3002, name: 'Elapsed time in current phase',   role: 'elapsed_time',   category: 'diagnostic', factor: 1.0, data_type: 'uint16', subtype: nil },
    { addr: 3003, name: 'Total duration of current phase', role: 'phase_duration', category: 'diagnostic', factor: 1.0, data_type: 'uint16', subtype: nil },
    { addr: 3004, name: 'Current phase number',            role: 'phase_number',   category: 'diagnostic', factor: 1.0, data_type: 'uint16', subtype: nil },
    { addr: 3005, name: 'Alarm code (live copy)',          role: 'alarm_code',     category: 'diagnostic', factor: 1.0, data_type: 'uint16', subtype: nil },
    { addr: 3006, name: 'Current program number',          role: 'program_number', category: 'diagnostic', factor: 1.0, data_type: 'uint16', subtype: nil },
    { addr: 3007, name: 'Status bitmask',                  role: 'status_bits',    category: 'diagnostic', factor: 1.0, data_type: 'uint16', subtype: nil }
  ]

  live_data_specs.each_with_index do |spec, i|
    create_fatek_register.call(
      {
        name:                         spec[:name],
        label:                        "LiveData_#{spec[:role].split('_').map(&:capitalize).join}",
        address:                      spec[:addr],
        register_type:                'holding',
        data_type:                    spec[:data_type],
        value_format:                 'numeric',
        factor:                       spec[:factor],
        category:                     spec[:category],
        read_only:                    true,
        group_name:                   'live_data',
        group_role:                   spec[:role],
        bulk_read_group:              'live_data',
        bulk_read_address:            3000,
        bulk_read_offset:             spec[:addr] - 3000,
        default_measurement_subtype:  spec[:subtype]
      },
      read_offset: 8 + i
    )
  end

  # ════════════════════════════════════════════════════════════════════════
  # Block 3: System status RW (writable controls scattered across address
  # space). All share group_name 'system_status' but have distinct
  # bulk_read_groups by address proximity.
  # ════════════════════════════════════════════════════════════════════════

  # R10 — Operating phase number (low-address holding block)
  create_fatek_register.call(
    {
      name:              'Operating phase number (0-indexed)',
      label:             'SystemStatus_OperatingPhase',
      address:           10,
      register_type:     'holding',
      data_type:         'uint16',
      value_format:      'numeric',
      category:          'configuration',
      read_only:         false,
      group_name:        'system_status',
      group_role:        'operating_phase',
      bulk_read_group:   'system_status_low',
      bulk_read_address: 10,
      bulk_read_offset:  0,
      min_value:         0,
      max_value:         14
    },
    read_offset:  16,
    write_offset: 670
  )

  # R60 — Program number
  create_fatek_register.call(
    {
      name:              'Program number',
      label:             'SystemStatus_ProgramSelect',
      address:           60,
      register_type:     'holding',
      data_type:         'uint16',
      value_format:      'numeric',
      category:          'configuration',
      read_only:         false,
      group_name:        'system_status',
      group_role:        'program_select',
      bulk_read_group:   'system_status_low',
      bulk_read_address: 10,
      bulk_read_offset:  50,
      min_value:         0,
      max_value:         3
    },
    read_offset:  22,
    write_offset: 671
  )

  # R3010 — External command code
  create_fatek_register.call(
    {
      name:              'External command code',
      label:             'SystemStatus_ExternalCommand',
      address:           3010,
      register_type:     'holding',
      data_type:         'uint16',
      value_format:      'numeric',
      category:          'configuration',
      read_only:         false,
      group_name:        'system_status',
      group_role:        'external_command',
      bulk_read_group:   'external_command',
      bulk_read_address: 3010,
      bulk_read_offset:  0
    },
    read_offset:  24,
    write_offset: 672
  )

  # R5512 — Local program selecting allowed/denied
  create_fatek_register.call(
    {
      name:              'Local program selecting allowed/denied',
      label:             'SystemStatus_LocalSelectAllow',
      address:           5512,
      register_type:     'holding',
      data_type:         'uint16',
      value_format:      'numeric',
      category:          'configuration',
      read_only:         false,
      group_name:        'system_status',
      group_role:        'local_select_allow',
      bulk_read_group:   'local_select',
      bulk_read_address: 5512,
      bulk_read_offset:  0
    },
    read_offset:  25,
    write_offset: 673
  )

  # Humidity control modes per program (R5124, R5252, R5380, R5508)
  # Each lives within its program's bulk_read_group.
  humidity_mode_specs = [
    { addr: 5124, prog: 0, role: 'humidity_mode_0', read_offset: 26, write_offset: 674, bulk_group: 'program_0', bulk_base: 5000 },
    { addr: 5252, prog: 1, role: 'humidity_mode_1', read_offset: 27, write_offset: 675, bulk_group: 'program_1', bulk_base: 5128 },
    { addr: 5380, prog: 2, role: 'humidity_mode_2', read_offset: 28, write_offset: 676, bulk_group: 'program_2', bulk_base: 5256 },
    { addr: 5508, prog: 3, role: 'humidity_mode_3', read_offset: 29, write_offset: 677, bulk_group: 'program_3', bulk_base: 5384 }
  ]

  humidity_mode_specs.each do |spec|
    create_fatek_register.call(
      {
        name:              "Humidity control mode for program #{spec[:prog]}",
        label:             "SystemStatus_#{spec[:role].split('_').map(&:capitalize).join}",
        address:           spec[:addr],
        register_type:     'holding',
        data_type:         'uint16',
        value_format:      'numeric',
        category:          'configuration',
        read_only:         false,
        group_name:        'system_status',
        group_role:        spec[:role],
        bulk_read_group:   spec[:bulk_group],
        bulk_read_address: spec[:bulk_base],
        bulk_read_offset:  spec[:addr] - spec[:bulk_base]
      },
      read_offset:  spec[:read_offset],
      write_offset: spec[:write_offset]
    )
  end

  # ════════════════════════════════════════════════════════════════════════
  # Block 4: System status RO (read-only diagnostic registers)
  # ════════════════════════════════════════════════════════════════════════

  ro_system_status_specs = [
    { addr: 12,   name: 'Displaying phase number',          role: 'displaying_phase', read_offset: 17, bulk_group: 'system_status_low', bulk_base: 10,   visibility: 'visible' },
    { addr: 15,   name: 'Program major version',            role: 'version_major',    read_offset: 18, bulk_group: 'system_status_low', bulk_base: 10,   visibility: 'hidden'  },
    { addr: 16,   name: 'Program minor version',            role: 'version_minor',    read_offset: 19, bulk_group: 'system_status_low', bulk_base: 10,   visibility: 'hidden'  },
    { addr: 17,   name: 'Program subversion',               role: 'version_sub',      read_offset: 20, bulk_group: 'system_status_low', bulk_base: 10,   visibility: 'hidden'  },
    { addr: 44,   name: 'Command codes loaded mark',        role: 'cmd_loaded_mark',  read_offset: 21, bulk_group: 'system_status_low', bulk_base: 10,   visibility: 'hidden'  },
    { addr: 61,   name: 'Adjusted record number',           role: 'adjusted_record',  read_offset: 23, bulk_group: 'system_status_low', bulk_base: 10,   visibility: 'hidden'  },
    { addr: 6000, name: 'Alarm code (D0)',                  role: 'alarm_code_d0',    read_offset: 30, bulk_group: 'alarm_code_d0',     bulk_base: 6000, visibility: 'visible' },
    { addr: 5254, name: 'Program 1 loaded mark',            role: 'prog1_loaded',     read_offset: 31, bulk_group: 'program_1',         bulk_base: 5128, visibility: 'hidden'  },
    { addr: 5382, name: 'Program 2 loaded mark',            role: 'prog2_loaded',     read_offset: 32, bulk_group: 'program_2',         bulk_base: 5256, visibility: 'hidden'  },
    { addr: 5510, name: 'Program 3 loaded mark',            role: 'prog3_loaded',     read_offset: 33, bulk_group: 'program_3',         bulk_base: 5384, visibility: 'hidden'  }
  ]

  ro_system_status_specs.each do |spec|
    create_fatek_register.call(
      {
        name:              spec[:name],
        label:             "SystemStatus_#{spec[:role].split('_').map(&:capitalize).join}",
        address:           spec[:addr],
        register_type:     'holding',
        data_type:         'uint16',
        value_format:      'numeric',
        category:          'diagnostic',
        read_only:         true,
        group_name:        'system_status',
        group_role:        spec[:role],
        bulk_read_group:   spec[:bulk_group],
        bulk_read_address: spec[:bulk_base],
        bulk_read_offset:  spec[:addr] - spec[:bulk_base],
        user_visibility:   spec[:visibility]
      },
      read_offset: spec[:read_offset]
    )
  end

  # ════════════════════════════════════════════════════════════════════════
  # Block 5: Parameters (R25..R41) — RW, gaps at R29 and R39
  # Read mirror preserves addr-relative offsets (R25→40, R41→56);
  # write buffer packs contiguously (650..664).
  # ════════════════════════════════════════════════════════════════════════

  parameter_specs = [
    { addr: 25, name: 'Humidity work limit hysteresis',    role: 'hum_work_hyst',         factor: 0.01 },
    { addr: 26, name: 'Humidity alarm limit hysteresis',   role: 'hum_alarm_hyst',        factor: 0.01 },
    { addr: 27, name: 'Temperature work limit hysteresis', role: 'temp_work_hyst',        factor: 0.01 },
    { addr: 28, name: 'Temperature alarm limit hysteresis',role: 'temp_alarm_hyst',       factor: 0.01 },
    { addr: 30, name: 'Heating ON delay',                  role: 'heating_on_delay',      factor: 0.1  },
    { addr: 31, name: 'Cooling ON delay',                  role: 'cooling_on_delay',      factor: 0.1  },
    { addr: 32, name: 'Wetting ON delay',                  role: 'wetting_on_delay',      factor: 0.1  },
    { addr: 33, name: 'Wetting OFF delay',                 role: 'wetting_off_delay',     factor: 0.1  },
    { addr: 34, name: 'Low temperature alarm delay',       role: 'low_temp_alarm_delay',  factor: 0.1  },
    { addr: 35, name: 'High temperature alarm delay',      role: 'high_temp_alarm_delay', factor: 0.1  },
    { addr: 36, name: 'Low humidity alarm delay',          role: 'low_hum_alarm_delay',   factor: 0.1  },
    { addr: 37, name: 'Wetting time in timer mode',        role: 'wetting_time_timer',    factor: 1.0  },
    { addr: 38, name: 'Constant 1 (MT6050i)',              role: 'mt6050i_const',         factor: 1.0  },
    { addr: 40, name: 'Humidity sensor offset',            role: 'humidity_sensor_offset',factor: 0.01 },
    { addr: 41, name: 'Temperature sensor offset',         role: 'temp_sensor_offset',    factor: 0.01 }
  ]

  parameter_specs.each_with_index do |spec, i|
    create_fatek_register.call(
      {
        name:              spec[:name],
        label:             "Parameter_#{spec[:role].split('_').map(&:capitalize).join}",
        address:           spec[:addr],
        register_type:     'holding',
        data_type:         'int16',
        value_format:      'numeric',
        factor:            spec[:factor],
        category:          'configuration',
        read_only:         false,
        group_name:        'parameters',
        group_role:        spec[:role],
        bulk_read_group:   'parameters',
        bulk_read_address: 25,
        bulk_read_offset:  spec[:addr] - 25
      },
      read_offset:  40 + (spec[:addr] - 25),
      write_offset: 650 + i
    )
  end

  # ════════════════════════════════════════════════════════════════════════
  # Block 6: Command buttons (R45..R49) — write-only triggers
  # ════════════════════════════════════════════════════════════════════════

  command_button_specs = [
    { addr: 45, name: 'Start command code',      role: 'start_cmd'   },
    { addr: 46, name: 'Reset command code',      role: 'reset_cmd'   },
    { addr: 47, name: 'Confirm command code',    role: 'confirm_cmd' },
    { addr: 48, name: 'Stop command code',       role: 'stop_cmd'    },
    { addr: 49, name: 'Copy set points to file', role: 'copy_sp_cmd' }
  ]

  command_button_specs.each_with_index do |spec, i|
    create_fatek_register.call(
      {
        name:              spec[:name],
        label:             "Command_#{spec[:role].sub(/_cmd\z/, '').split('_').map(&:capitalize).join}",
        address:           spec[:addr],
        register_type:     'holding',
        data_type:         'uint16',
        value_format:      'numeric',
        category:          'configuration',
        read_only:         false,
        group_name:        'command_buttons',
        group_role:        spec[:role],
        bulk_read_group:   'command_buttons',
        bulk_read_address: 45,
        bulk_read_offset:  spec[:addr] - 45
      },
      write_offset: 665 + i
    )
  end

  # ════════════════════════════════════════════════════════════════════════
  # Block 7: Programs 0..3 (R5000..R5503) — 15 phases × 8 fields each
  # ════════════════════════════════════════════════════════════════════════

  PHASE_FIELDS = [
    { offset: 0, name: 'Temperature low work limit',   role: 'temp_low_work',    factor: 0.01, data_type: 'int16'  },
    { offset: 1, name: 'Temperature high work limit',  role: 'temp_high_work',   factor: 0.01, data_type: 'int16'  },
    { offset: 2, name: 'Temperature low alarm limit',  role: 'temp_low_alarm',   factor: 0.01, data_type: 'int16'  },
    { offset: 3, name: 'Temperature high alarm limit', role: 'temp_high_alarm',  factor: 0.01, data_type: 'int16'  },
    { offset: 4, name: 'Humidity work limit',          role: 'humidity_work',    factor: 0.01, data_type: 'int16'  },
    { offset: 5, name: 'Humidity alarm limit',         role: 'humidity_alarm',   factor: 0.01, data_type: 'int16'  },
    { offset: 6, name: 'Phase duration',               role: 'duration',         factor: 1.0,  data_type: 'uint16' },
    { offset: 7, name: 'Last phase mark',              role: 'last_phase_mark',  factor: 1.0,  data_type: 'uint16' }
  ].freeze

  PROGRAM_BASES = [5000, 5128, 5256, 5384].freeze

  PROGRAM_BASES.each_with_index do |prog_base, prog_idx|
    bulk_group       = "program_#{prog_idx}"
    read_block_base  = 60  + (prog_idx * 120)
    write_block_base = 680 + (prog_idx * 120)

    15.times do |phase_idx|
      PHASE_FIELDS.each do |field|
        relative_offset = (phase_idx * 8) + field[:offset]
        addr            = prog_base + relative_offset

        create_fatek_register.call(
          {
            name:              "Program #{prog_idx} phase #{phase_idx + 1} #{field[:name].downcase}",
            label:             "Program#{prog_idx}Phase#{phase_idx + 1}_#{field[:role].split('_').map(&:capitalize).join}",
            address:           addr,
            register_type:     'holding',
            data_type:         field[:data_type],
            value_format:      'numeric',
            factor:            field[:factor],
            category:          'configuration',
            read_only:         false,
            group_name:        "program_#{prog_idx}_phase_#{phase_idx + 1}",
            group_role:        field[:role],
            bulk_read_group:   bulk_group,
            bulk_read_address: prog_base,
            bulk_read_offset:  relative_offset
          },
          read_offset:  read_block_base  + relative_offset,
          write_offset: write_block_base + relative_offset
        )
      end
    end
  end

  # ════════════════════════════════════════════════════════════════════════
  # Block 8: Timers + counter (T50..T62, T70, T200..T201, C0)
  # ════════════════════════════════════════════════════════════════════════

  timer_specs = [
    { addr: 9050, name: 'Reset delay timer (T50)',                   role: 't50',  read_offset: 540, write_offset: 1160, bulk_group: 'timers_main',    bulk_base: 9050 },
    { addr: 9051, name: 'Minute timer (T51)',                        role: 't51',  read_offset: 541, write_offset: 1161, bulk_group: 'timers_main',    bulk_base: 9050 },
    { addr: 9052, name: 'Heating delay timer (T52)',                 role: 't52',  read_offset: 542, write_offset: 1162, bulk_group: 'timers_main',    bulk_base: 9050 },
    { addr: 9053, name: 'Cooling delay timer (T53)',                 role: 't53',  read_offset: 543, write_offset: 1163, bulk_group: 'timers_main',    bulk_base: 9050 },
    { addr: 9054, name: 'Low temperature alarm delay timer (T54)',   role: 't54',  read_offset: 544, write_offset: 1164, bulk_group: 'timers_main',    bulk_base: 9050 },
    { addr: 9055, name: 'High temperature alarm delay timer (T55)',  role: 't55',  read_offset: 545, write_offset: 1165, bulk_group: 'timers_main',    bulk_base: 9050 },
    { addr: 9056, name: 'Wetting ON delay timer (T56)',              role: 't56',  read_offset: 546, write_offset: 1166, bulk_group: 'timers_main',    bulk_base: 9050 },
    { addr: 9057, name: 'Wetting alarm delay timer (T57)',           role: 't57',  read_offset: 547, write_offset: 1167, bulk_group: 'timers_main',    bulk_base: 9050 },
    { addr: 9058, name: 'Wetting OFF delay timer (T58)',             role: 't58',  read_offset: 548, write_offset: 1168, bulk_group: 'timers_main',    bulk_base: 9050 },
    { addr: 9060, name: 'Start delay timer (T60)',                   role: 't60',  read_offset: 549, write_offset: 1169, bulk_group: 'timers_main',    bulk_base: 9050 },
    { addr: 9061, name: 'Blink period timer (T61)',                  role: 't61',  read_offset: 550, write_offset: 1170, bulk_group: 'timers_main',    bulk_base: 9050 },
    { addr: 9062, name: 'Humidity control ON/OFF delay timer (T62)', role: 't62',  read_offset: 551, write_offset: 1171, bulk_group: 'timers_main',    bulk_base: 9050 },
    { addr: 9070, name: 'External command reset delay timer (T70)',  role: 't70',  read_offset: 553, write_offset: 1173, bulk_group: 'timers_main',    bulk_base: 9050 },
    { addr: 9200, name: 'Wetting ON timer in timer mode (T200)',     role: 't200', read_offset: 554, write_offset: 1174, bulk_group: 'timers_wetting', bulk_base: 9200 },
    { addr: 9201, name: 'Wetting OFF time in timer mode (T201)',     role: 't201', read_offset: 555, write_offset: 1175, bulk_group: 'timers_wetting', bulk_base: 9200 },
    { addr: 9500, name: 'Current phase time counter (C0)',           role: 'c0',   read_offset: 556, write_offset: 1176, bulk_group: 'counter_c0',     bulk_base: 9500 }
  ]

  timer_specs.each do |spec|
    create_fatek_register.call(
      {
        name:              spec[:name],
        label:             "Timer_#{spec[:role].upcase}",
        address:           spec[:addr],
        register_type:     'holding',
        data_type:         'uint16',
        value_format:      'numeric',
        category:          'configuration',
        read_only:         false,
        group_name:        'timers',
        group_role:        spec[:role],
        bulk_read_group:   spec[:bulk_group],
        bulk_read_address: spec[:bulk_base],
        bulk_read_offset:  spec[:addr] - spec[:bulk_base],
        user_visibility:   'hidden'
      },
      read_offset:  spec[:read_offset],
      write_offset: spec[:write_offset]
    )
  end

  # ════════════════════════════════════════════════════════════════════════
  # Block 9: Coil outputs Y0..Y8 — RO (ladder-driven physical outputs)
  # Mirrored into slot holding register space via host ST code.
  # ════════════════════════════════════════════════════════════════════════

  output_specs = [
    { addr: 0, name: 'Lamp: Process',                   role: 'lamp_process'        },
    { addr: 1, name: 'Lamp: Alarm',                     role: 'lamp_alarm'          },
    { addr: 2, name: 'Heating output',                  role: 'heating'             },
    { addr: 3, name: 'Cooling output',                  role: 'cooling'             },
    { addr: 4, name: 'Wetting output',                  role: 'wetting'             },
    { addr: 5, name: 'Buzzer',                          role: 'buzzer'              },
    { addr: 6, name: 'Lamp: Finish',                    role: 'lamp_finish'         },
    { addr: 7, name: 'Lamp: Humidity control by timer', role: 'lamp_humidity_timer' },
    { addr: 8, name: 'Humidity control disabled',       role: 'humidity_disabled'   }
  ]

  output_specs.each_with_index do |spec, i|
    create_fatek_register.call(
      {
        name:              spec[:name],
        label:             "Output_#{spec[:role].split('_').map(&:capitalize).join}",
        address:           spec[:addr],
        register_type:     'coil',
        data_type:         'boolean',
        value_format:      'boolean',
        category:          'status',
        read_only:         true,
        group_name:        'outputs',
        group_role:        spec[:role],
        bulk_read_group:   'outputs_y',
        bulk_read_address: 0,
        bulk_read_offset:  spec[:addr]
      },
      read_offset: 560 + i
    )
  end

  # ════════════════════════════════════════════════════════════════════════
  # Block 10: Memory bits M0..M65 + M800 (mixed RO state + RW commands)
  # All M0..M65 share bulk_read_group 'memory_bits' for read optimization.
  # group_name distinguishes 'memory_bits_state' (RO) from
  # 'memory_bits_command' (RW) for UI grouping.
  # ════════════════════════════════════════════════════════════════════════

  ro_memory_bits = [
    { addr: 2000, name: 'Process state',                          role: 'process_state',         offset: 570, visibility: 'visible' },
    { addr: 2001, name: 'Confirmed state',                        role: 'confirmed_state',       offset: 571, visibility: 'visible' },
    { addr: 2010, name: 'No operating voltage',                   role: 'no_voltage',            offset: 572, visibility: 'hidden'  },
    { addr: 2011, name: 'Error copying set points to file',       role: 'copy_sp_error',         offset: 573, visibility: 'hidden'  },
    { addr: 2012, name: 'Set points copied to file successfully', role: 'copy_sp_ok',            offset: 574, visibility: 'hidden'  },
    { addr: 2013, name: 'Program changing allowed',               role: 'prog_change_allowed',   offset: 575, visibility: 'visible' },
    { addr: 2014, name: 'Program 0 selected',                     role: 'prog0_selected',        offset: 576, visibility: 'visible' },
    { addr: 2015, name: 'All programs loaded',                    role: 'all_progs_loaded',      offset: 577, visibility: 'hidden'  },
    { addr: 2016, name: 'Program not exists',                     role: 'prog_not_exists',       offset: 578, visibility: 'visible' },
    { addr: 2017, name: 'Incorrect humidity data',                role: 'bad_humidity_data',     offset: 579, visibility: 'visible' },
    { addr: 2018, name: 'Incorrect temperature data',             role: 'bad_temp_data',         offset: 580, visibility: 'visible' },
    { addr: 2020, name: 'Current phase finished',                 role: 'phase_finished',        offset: 581, visibility: 'visible' },
    { addr: 2049, name: 'Manual sprinkling activated',            role: 'manual_sprinkling',     offset: 597, visibility: 'visible' },
    { addr: 2050, name: 'Reset executing command',                role: 'exec_reset',            offset: 598, visibility: 'hidden'  },
    { addr: 2051, name: 'One more minute',                        role: 'one_more_minute',       offset: 599, visibility: 'hidden'  },
    { addr: 2052, name: 'Heating executing command',              role: 'exec_heating',          offset: 600, visibility: 'visible' },
    { addr: 2053, name: 'Cooling executing command',              role: 'exec_cooling',          offset: 601, visibility: 'visible' },
    { addr: 2054, name: 'Low temperature alarm',                  role: 'alarm_low_temp',        offset: 602, visibility: 'visible' },
    { addr: 2055, name: 'High temperature alarm',                 role: 'alarm_high_temp',       offset: 603, visibility: 'visible' },
    { addr: 2056, name: 'Wetting ON executing command',           role: 'exec_wetting_on',       offset: 604, visibility: 'visible' },
    { addr: 2057, name: 'Low humidity alarm',                     role: 'alarm_low_humidity',    offset: 605, visibility: 'visible' },
    { addr: 2058, name: 'Wetting OFF executing command',          role: 'exec_wetting_off',      offset: 606, visibility: 'hidden'  },
    { addr: 2059, name: 'Humidity control toggle executing',      role: 'exec_humidity_toggle',  offset: 607, visibility: 'hidden'  },
    { addr: 2060, name: 'Start executing command',                role: 'exec_start',            offset: 608, visibility: 'hidden'  },
    { addr: 2061, name: 'Blink bit',                              role: 'blink',                 offset: 609, visibility: 'hidden'  },
    { addr: 2062, name: 'Auxiliary blink bit',                    role: 'blink_aux',             offset: 610, visibility: 'hidden'  },
    { addr: 2063, name: 'Alarm conditions',                       role: 'alarm_conditions',      offset: 611, visibility: 'visible' },
    { addr: 2064, name: 'Prepare data for new phase',             role: 'prep_new_phase',        offset: 612, visibility: 'hidden'  },
    { addr: 2065, name: 'Process finished',                       role: 'process_finished',      offset: 613, visibility: 'visible' }
  ]

  ro_memory_bits.each do |spec|
    create_fatek_register.call(
      {
        name:              spec[:name],
        label:             "MemoryBit_#{spec[:role].split('_').map(&:capitalize).join}",
        address:           spec[:addr],
        register_type:     'coil',
        data_type:         'boolean',
        value_format:      'boolean',
        category:          'status',
        read_only:         true,
        group_name:        'memory_bits_state',
        group_role:        spec[:role],
        bulk_read_group:   'memory_bits',
        bulk_read_address: 2000,
        bulk_read_offset:  spec[:addr] - 2000,
        user_visibility:   spec[:visibility]
      },
      read_offset: spec[:offset]
    )
  end

  # M800 — Process memorization (separate bulk group: address 2800 is too
  # far from the M0..M65 block to fit in a single bulk read).
  create_fatek_register.call(
    {
      name:              'Process memorization',
      label:             'MemoryBit_ProcessMemorization',
      address:           2800,
      register_type:     'coil',
      data_type:         'boolean',
      value_format:      'boolean',
      category:          'status',
      read_only:         true,
      group_name:        'memory_bits_state',
      group_role:        'process_memorization',
      bulk_read_group:   'memory_bit_800',
      bulk_read_address: 2800,
      bulk_read_offset:  0,
      user_visibility:   'hidden'
    },
    read_offset: 614
  )

  # Writable command bits (on-screen buttons + external command bits).
  # Read offsets sit in the M30..M47 range of the read mirror (582..596);
  # write offsets are packed in 1177..1191.
  rw_memory_bits = [
    { addr: 2030, name: 'Start (on-screen button)',           role: 'start_screen',      read_offset: 582, write_offset: 1177 },
    { addr: 2031, name: 'Reset (on-screen button)',           role: 'reset_screen',      read_offset: 583, write_offset: 1178 },
    { addr: 2032, name: 'Confirm (on-screen button)',         role: 'confirm_screen',    read_offset: 584, write_offset: 1179 },
    { addr: 2033, name: 'Stop (on-screen button)',            role: 'stop_screen',       read_offset: 585, write_offset: 1180 },
    { addr: 2036, name: 'Manual heating (on-screen)',         role: 'manual_heating',    read_offset: 586, write_offset: 1181 },
    { addr: 2037, name: 'Manual cooling (on-screen)',         role: 'manual_cooling',    read_offset: 587, write_offset: 1182 },
    { addr: 2038, name: 'Manual sprinkling (on-screen)',      role: 'manual_sprink',     read_offset: 588, write_offset: 1183 },
    { addr: 2040, name: 'Start (external command)',           role: 'start_external',    read_offset: 589, write_offset: 1184 },
    { addr: 2041, name: 'Reset (external command)',           role: 'reset_external',    read_offset: 590, write_offset: 1185 },
    { addr: 2042, name: 'Confirm (external command)',         role: 'confirm_external',  read_offset: 591, write_offset: 1186 },
    { addr: 2043, name: 'Stop (external command)',            role: 'stop_external',     read_offset: 592, write_offset: 1187 },
    { addr: 2044, name: 'Copy SPs to file (external)',        role: 'copy_sp_external',  read_offset: 593, write_offset: 1188 },
    { addr: 2045, name: 'Read phase SP (external)',           role: 'read_sp_external',  read_offset: 594, write_offset: 1189 },
    { addr: 2046, name: 'Humidity control mode (external)',   role: 'hum_mode_external', read_offset: 595, write_offset: 1190 },
    { addr: 2047, name: 'Humidity control OFF (external)',    role: 'hum_off_external',  read_offset: 596, write_offset: 1191 }
  ]

  rw_memory_bits.each do |spec|
    create_fatek_register.call(
      {
        name:              spec[:name],
        label:             "MemoryBit_#{spec[:role].split('_').map(&:capitalize).join}",
        address:           spec[:addr],
        register_type:     'coil',
        data_type:         'boolean',
        value_format:      'boolean',
        category:          'configuration',
        read_only:         false,
        group_name:        'memory_bits_command',
        group_role:        spec[:role],
        bulk_read_group:   'memory_bits',
        bulk_read_address: 2000,
        bulk_read_offset:  spec[:addr] - 2000
      },
      read_offset:  spec[:read_offset],
      write_offset: spec[:write_offset]
    )
  end

  # ════════════════════════════════════════════════════════════════════════
  # Block 11: Physical input buttons X0..X7 — RO discretes
  # ════════════════════════════════════════════════════════════════════════

  physical_input_specs = [
    { addr: 1000, name: 'Start (physical button)',     role: 'start_button',    offset: 620 },
    { addr: 1001, name: 'Reset (physical button)',     role: 'reset_button',    offset: 621 },
    { addr: 1002, name: 'Confirm (physical button)',   role: 'confirm_button',  offset: 622 },
    { addr: 1003, name: 'Stop (physical button)',      role: 'stop_button',     offset: 623 },
    { addr: 1004, name: 'Humidity timer-mode toggle',  role: 'humidity_toggle', offset: 624 },
    { addr: 1005, name: 'Manual sprinkling button',    role: 'sprink_button',   offset: 625 },
    { addr: 1007, name: 'Operating voltage exists',    role: 'voltage_ok',      offset: 626 }
  ]

  physical_input_specs.each do |spec|
    create_fatek_register.call(
      {
        name:              spec[:name],
        label:             "Input_#{spec[:role].split('_').map(&:capitalize).join}",
        address:           spec[:addr],
        register_type:     'coil',
        data_type:         'boolean',
        value_format:      'boolean',
        category:          'status',
        read_only:         true,
        group_name:        'physical_inputs',
        group_role:        spec[:role],
        bulk_read_group:   'physical_inputs',
        bulk_read_address: 1000,
        bulk_read_offset:  spec[:addr] - 1000,
        user_visibility:   'hidden'
      },
      read_offset: spec[:offset]
    )
  end
end
