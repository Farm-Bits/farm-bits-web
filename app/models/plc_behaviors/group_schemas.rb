module PlcBehaviors
  module GroupSchemas
    DEFINITIONS = {
      # ── System groups ──────────────────────────
      'set_system_clock' => {
        required_roles: %w[seconds minutes hours day_of_week day_of_month month year upload_trigger]
      },
      'sun_data' => {
        required_roles: %w[sunrise sunset]
      },
      'time_config' => {
        required_roles: %w[utc_offset]
      },
      'io_active' => {
        required_roles: []  # wildcard pattern, validated differently
      },

      # ── Operation Mode ─────────────────────────
      'om_status' => {
        label: 'Status',
        required_roles: %w[active_source]
      },
      'om_manual' => {
        label: 'Manual Control',
        required_roles: %w[command]
      },
      'om_duty_cycle' => {
        label: 'Duty Cycle',
        required_roles: %w[enabled on_duration off_duration]
      },
      'om_sensor' => {
        label: 'Sensor Trigger',
        required_roles: %w[enabled]
      },
      'om_sensor_cond_*' => {
        label: 'Condition',
        required_roles: %w[enabled source_type source_io_number operator threshold]
      },
      'om_schedule_*' => {
        label: 'Schedule',
        required_roles: %w[enabled start_ref start_time duration]
      },
      'om_window' => {
        label: 'Time Window',
        required_roles: %w[enabled start_ref start_time end_ref end_time days]
      },
      'om_safety' => {
        label: 'Safety',
        required_roles: %w[emergency_stop]
      },

      # ── Programs (generic, used by any firmware with program/phase blocks) ──
      'program_*_phase_*' => {
        label: 'Phase',
        required_roles: [],
        structure: { kind: :item, container_index: 0, item_index: 1 }
      },
      'program_*_meta' => {
        label: 'Program',
        required_roles: [],
        structure: { kind: :container, container_index: 0 }
      },

      # ── System config (device-level, non-interface) ─────────────────────────
      'system_hysteresis' => {
        label: 'Hysteresis',
        required_roles: %w[
          humidity_work_hysteresis humidity_alarm_hysteresis
          temp_work_hysteresis temp_alarm_hysteresis
        ]
      },
      'system_delays' => {
        label: 'Delays & Timers',
        required_roles: %w[
          heating_on_delay cooling_on_delay
          wetting_on_delay wetting_off_delay
          temp_low_alarm_delay temp_high_alarm_delay
          humidity_low_alarm_delay
          wetting_timer_seconds
        ]
      },
      'system_offsets' => {
        label: 'Sensor Offsets',
        required_roles: %w[humidity_sensor_offset temp_sensor_offset]
      },
      'system_commands' => {
        label: 'Commands',
        required_roles: %w[start reset confirm stop copy_setpoints_to_file]
      }
    }.freeze

    def self.schema_for(group_name)
      # Direct match first, then try wildcard
      DEFINITIONS[group_name] || DEFINITIONS.find { |pattern, _|
        pattern.include?('*') && group_name.match?(Regexp.new("\\A#{pattern.gsub('*', '\\d+')}\\z"))
      }&.last
    end

    def self.validate_modbus_firmware_version!(modbus_firmware_version)
      errors = []

      modbus_firmware_version.register_templates.group_by(&:group_name).each do |group_name, templates|
        if !group_name.present?
          next
        end

        schema = schema_for(group_name)
        if !schema
          next  # Unknown group — no contract to enforce
        end

        existing_roles = templates.map(&:group_role).compact
        missing = schema[:required_roles] - existing_roles

        if missing.any?
          errors << "#{group_name}: missing required roles: #{missing.join(', ')}"
        end
      end

      errors
    end

    def self.label_for(group_name)
      schema = schema_for(group_name)
      schema&.dig(:label)
    end

    def self.group_labels
      DEFINITIONS
        .select { |_, schema| schema[:label].present? }
        .transform_values { |schema| schema[:label] }
    end

    def self.parse_indices(group_name)
      match = DEFINITIONS.lazy.filter_map do |pattern, schema|
        if !pattern.include?('*')
          next nil
        end

        regex = Regexp.new('\A' + pattern.gsub('*', '(\d+)') + '\z')
        m = regex.match(group_name)
        if !m
          next nil
        end

        [pattern, schema, m.captures.map(&:to_i)]
      end.first

      if !match
        return nil
      end

      pattern, schema, captures = match
      structure = schema[:structure]
      if !structure
        return { pattern: pattern, captures: captures }
      end

      result = { pattern: pattern, kind: structure[:kind], captures: captures }
      if structure[:container_index]
        result[:container] = captures[structure[:container_index]]
      end
      if structure[:item_index]
        result[:item] = captures[structure[:item_index]]
      end
      result
    end
  end
end
