# app/models/plc_behaviors/standard_v1.rb
#
# Behavior profile for the standard FarmBits PLC.
#
# This file is the complete picture of what this PLC version supports.
# Open it and you see:
#   - Which behaviors are enabled (the include lines)
#   - Which register groups the firmware uses (SYSTEM_GROUPS)
#
# To reuse this for a PLC with different IO counts (e.g., 8 AI instead of 12):
#   - Just create a new PlcVersion with 8 analog_input interfaces
#   - Set behavior_profile: 'standard_v1'
#   - Everything adapts automatically (bitmasks, push thresholds, sensor cascade)
#
# To create a version with different behavior:
#   1. Create a new file (e.g., standard_v2.rb)
#   2. Include only the concerns you need
#   3. Adjust SYSTEM_GROUPS if the register layout differs
#   4. Add to PlcBehaviors::REGISTRY
#   5. Set behavior_profile on the PlcVersion record
#
class PlcBehaviors::StandardV1 < PlcBehaviors::Base

  # ════════════════════════════════════════════════════════════
  # BEHAVIORS
  # ════════════════════════════════════════════════════════════

  include PlcBehaviors::Concerns::ClockSyncUtc             # sync_clock!, sync_utc_offset!
  # include PlcBehaviors::Concerns::IoActiveBitmask          # sync_io_active!
  include PlcBehaviors::Concerns::SunDataSync              # sync_sun_data!
  include PlcBehaviors::Concerns::SensorCascade            # cascade_sensor_deactivation!
  include PlcBehaviors::Concerns::OnetimeScheduleCleanup   # cleanup_onetime_schedules!

  # ════════════════════════════════════════════════════════════
  # REGISTER SCHEMA
  # ════════════════════════════════════════════════════════════
  #
  # Roles are explicit when the list is fixed (e.g., sunrise/sunset).
  # Roles use role_patterns when the count depends on the number of
  # interfaces (e.g., push thresholds — one per AI, one per DI).
  #
  # Pattern-based groups (om_schedule_*, om_sensor_cond_*) have a
  # fixed set of roles per instance, but the number of instances
  # varies per DO.

  SYSTEM_GROUPS = {
    # ── Clock & Time ──────────────────────────────────
    'set_system_clock' => {
      description: 'PLC clock registers (UTC). Written daily.',
      roles: %w[seconds minutes hours day_of_week day_of_month month year upload_trigger]
    },
    'time_config' => {
      description: 'UTC offset for local time derivation.',
      roles: %w[utc_offset]
    },

    # ── Global Configuration ──────────────────────────
    'io_active' => {
      description: 'IO active bitmasks. One uint16 per IO type, each bit = one interface number.',
      roles: %w[active_ai_* active_di_* active_do_* active_ao_*]
    },
    'push_data_config' => {
      description: 'Per-IO push data change thresholds. ' \
                   'AI: 0.1% units (20=2.0%). DI/FDI counters: absolute change (1=every increment).',
      role_patterns: %w[threshold_ai_* threshold_di_counter_*]
    },
    'sun_data' => {
      description: 'Sunrise/sunset in local minutes-since-midnight.',
      roles: %w[sunrise sunset]
    },
    'smtp_config' => {
      description: 'SMTP credentials for push data emails.',
      roles: %w[hostname port username password to_email]
    },

    # ── IO Health Detection (per input interface) ─────
    'io_health' => {
      description: 'Configurable error detection per input interface.',
      roles: %w[detect_mode detect_value_1 detect_value_2 health_status]
    },

    # ── Operation Mode Status (per DO) ────────────────
    'om_status' => {
      description: 'Read-only DO status: output state, active source, timers, predictions.',
      roles: %w[
        output_state active_source manual_remaining duty_remaining duty_phase
        on_elapsed off_elapsed error_flags sensor_result
        next_change_time next_change_target next_change_source
      ]
    },

    # ── Operation Mode Control (per DO) ───────────────
    'om_manual' => {
      description: 'Manual ON/OFF control with optional duration.',
      roles: %w[command duration]
    },
    'om_safety' => {
      description: 'Safety: max on, min off/on, blackout window, emergency stop.',
      roles: %w[max_on min_off min_on blackout_start blackout_end blackout_days emergency]
    },
    'om_duty_cycle' => {
      description: 'Duty cycle: ON/OFF phase durations.',
      roles: %w[enabled on_duration off_duration total_duration]
    },
    'om_duty_cycle_window' => {
      description: 'Optional time window for duty cycle.',
      roles: %w[start_ref start_time end_ref end_time days onetime_date]
    },
    'om_sensor' => {
      description: 'Sensor trigger master enable.',
      roles: %w[enabled]
    },
    'om_sensor_window' => {
      description: 'Optional time window for sensor trigger.',
      roles: %w[start_ref start_time end_ref end_time days onetime_date]
    },

    # ── Pattern-based groups ──────────────────────────
    'om_schedule_*' => {
      description: 'Schedule slots. Recurring weekly or one-time (with onetime_year for full date).',
      roles: %w[start_ref start_time duration days onetime_month onetime_day onetime_year],
      pattern: true
    },
    'om_sensor_cond_*' => {
      description: 'Sensor conditions. Reference IO via source_type + source_io_number.',
      roles: %w[source_type source_io_number operator threshold hysteresis logic on_error],
      pattern: true
    }
  }.freeze
end
