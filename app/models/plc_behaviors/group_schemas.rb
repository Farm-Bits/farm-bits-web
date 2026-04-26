module PlcBehaviors
  module GroupSchemas
    DEFINITIONS = {
      # ── System groups ──────────────────────────
      'set_system_clock' => {
        required_roles: %w[seconds minutes hours day_of_week day_of_month month year upload_trigger],
      },
      'sun_data' => {
        required_roles: %w[sunrise sunset],
      },
      'time_config' => {
        required_roles: %w[utc_offset],
      },
      'io_active' => {
        required_roles: [],  # wildcard pattern, validated differently
      },

      # ── Operation Mode ─────────────────────────
      'om_status' => {
        label: 'Status',
        required_roles: %w[active_source],
      },
      'om_manual' => {
        label: 'Manual Control',
        required_roles: %w[command],
      },
      'om_duty_cycle' => {
        label: 'Duty Cycle',
        required_roles: %w[enabled on_duration off_duration],
      },
      'om_sensor' => {
        label: 'Sensor Trigger',
        required_roles: %w[enabled],
      },
      'om_sensor_cond_*' => {
        label: 'Condition',
        required_roles: %w[enabled source_type source_io_number operator threshold],
      },
      'om_schedule_*' => {
        label: 'Schedule',
        required_roles: %w[enabled start_ref start_time duration],
      },
      'om_window' => {
        label: 'Time Window',
        required_roles: %w[enabled start_ref start_time end_ref end_time days],
      },
      'om_safety' => {
        label: 'Safety',
        required_roles: %w[emergency_stop],
      },
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
  end
end
