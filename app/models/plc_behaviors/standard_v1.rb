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
  include PlcBehaviors::Concerns::IoActive                 # sync_io_active!
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
      ],
      ui_hints: {
        renderer: 'status_summary',
        position: 0,
        role_map: {
          'output_state' => 'output_state',
          'active_source' => 'active_source',
          'on_elapsed' => 'on_elapsed',
          'off_elapsed' => 'off_elapsed',
          'next_change_seconds' => 'next_change_time',
          'next_change_target' => 'next_change_target',
          'next_change_source' => 'next_change_source',
          'error_flags' => 'error_flags',
          'manual_remaining' => 'manual_remaining',
          'duty_phase' => 'duty_phase',
          'duty_remaining' => 'duty_remaining',
          'sensor_result' => 'sensor_result',
        }
      }
    },

    # ── Operation Mode Control (per DO) ───────────────
    'om_manual' => {
      description: 'Manual ON/OFF control with optional duration.',
      roles: %w[command duration],
      ui_hints: {
        renderer: 'manual_control',
        position: 10,
        role_map: {
          'command' => 'command',
        },
        transient_roles: %w[command]
      }
    },
    'om_safety' => {
      description: 'Safety: max on, min off/on, blackout window, emergency stop.',
      roles: %w[max_on min_off min_on blackout_start blackout_end blackout_days emergency],
      ui_hints: {
        renderer: 'safety_constraints',
        position: 20,
        role_map: {
          'emergency' => 'emergency',
        },
        restricted_roles: {
          'emergency' => { 'release_min_role' => 'site_admin' },
        }
      }
    },
    'om_duty_cycle' => {
      description: 'Duty cycle: ON/OFF phase durations.',
      roles: %w[
        enabled on_duration off_duration total_duration
        window_enabled window_start_ref window_start_time
        window_end_ref window_end_time window_days window_onetime_date
      ],
      ui_hints: {
        renderer: 'duty_cycle',
        position: 40,
        role_map: {
          'enabled' => 'enabled',
          'window_enabled' => 'window_enabled',
        }
      }
    },
    'om_sensor' => {
      description: 'Sensor trigger master enable.',
      roles: %w[
        enabled
        window_enabled window_start_ref window_start_time
        window_end_ref window_end_time window_days window_onetime_date
      ],
      ui_hints: {
        renderer: 'sensor_trigger',
        children_pattern: 'om_sensor_cond_*',
        position: 50,
        role_map: {
          'enabled' => 'enabled',
          'window_enabled' => 'window_enabled',
        }
      }
    },
    # ── Pattern-based groups ──────────────────────────
    'om_schedule_*' => {
      description: 'Schedule slots. Recurring weekly or one-time (with onetime_year for full date).',
      roles: %w[enabled start_ref start_time duration days onetime_month onetime_day onetime_year],
      pattern: true,
      ui_hints: {
        renderer: 'schedule_slot',
        position: 30,
        role_map: {
          'enabled' => 'enabled',
        },
      }
    },
    'om_sensor_cond_*' => {
      description: 'Sensor conditions. Reference IO via source_type + source_io_number.',
      roles: %w[enabled source_type source_io_number operator threshold hysteresis logic on_error],
      pattern: true,
      ui_hints: {
        renderer: 'sensor_condition',
        position: 51,
        role_map: {
          'enabled' => 'enabled',
          'source_type' => 'source_type',
          'threshold' => 'threshold',
          'logic' => 'logic'
        }
      }
    }
  }.freeze
end
