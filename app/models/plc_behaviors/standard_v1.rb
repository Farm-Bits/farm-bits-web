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
    'set_system_clock' => {
      description: 'PLC clock registers (UTC)',
      roles: %w[seconds minutes hours day_of_week day_of_month month year upload_trigger]
    },
    'smtp_push_data' => {
      description: 'SMTP credentials for push data emails',
      roles: %w[hostname port username password to_email]
    },
    'time_config' => {
      description: 'UTC offset for local time derivation',
      roles: %w[utc_offset]
    },
    'sun_data' => {
      description: 'Sunrise/sunset in local minutes-since-midnight',
      roles: %w[sunrise sunset]
    },
    'io_active' => {
      description: 'IO active booleans. One per interface.',
      roles: %w[active_ai_* active_di_* active_do_* active_ao_*]
    },
    'push_data_thresholds' => {
      description: 'Per-IO push data change thresholds',
      role_patterns: %w[threshold_ai_* threshold_di_counter_*]
    },
    'io_health' => {
      description: 'Configurable error detection per input interface',
      roles: %w[detect_mode detect_value_1 detect_value_2 health_status]
    },

    # ── Operation Mode groups ─────────────────────────────────

    'om_safety' => {
      description: 'Safety constraints: emergency stop, max on, min off/on',
      roles: %w[
        emergency_stop
        max_on_enabled max_on
        min_off_enabled min_off
        min_on_enabled min_on
      ],
      ui_hints: {
        position: 1,
        quick_actions: {
          'emergency_stop' => { style: 'danger' }
        },
        restricted_roles: {
          'emergency_stop' => { min_role: 'site_admin' }
        }
      }
    },
    'om_window' => {
      description: 'Time window: if enabled, output can only be ON during this window',
      roles: %w[enabled start_ref start_time start_offset end_ref end_time end_offset days],
      ui_hints: {
        position: 5,
        toggle_role: 'enabled'
      }
    },
    'om_status' => {
      description: 'Operation mode status: active source, error flags, next change time',
      roles: %w[active_source error_flags next_change_time],
      ui_hints: {
        position: 0
      }
    },
    'om_manual' => {
      description: 'Manual ON/OFF control with optional timed duration',
      roles: %w[command duration],
      ui_hints: {
        position: 10,
        quick_actions: {
          'command' => { style: 'primary' }
        }
      }
    },
    'om_duty_cycle' => {
      description: 'Duty cycle: repeating ON/OFF phases',
      roles: %w[enabled on_duration off_duration],
      ui_hints: {
        position: 20,
        toggle_role: 'enabled'
      }
    },
    'om_sensor' => {
      description: 'Sensor trigger master enable',
      roles: %w[enabled],
      ui_hints: {
        position: 30,
        toggle_role: 'enabled',
        children_pattern: 'om_sensor_cond_*'
      }
    },
    'om_sensor_cond_*' => {
      description: 'Individual sensor conditions. IO via source_type + source_io_number.',
      roles: %w[enabled source_type source_io_number operator threshold hysteresis],
      pattern: true,
      ui_hints: {
        position: 31,
        toggle_role: 'enabled',
        resettable: true,
        composite_fields: [
          { type: 'measurement_point_selector', roles: { io_type: 'source_type', io_number: 'source_io_number' } }
        ]
      }
    },
    'om_schedule_*' => {
      description: 'Schedule slots. Recurring weekly or one-time.',
      roles: %w[
        enabled action start_ref start_time start_offset duration schedule_type
        days onetime_day onetime_month onetime_year
      ],
      pattern: true,
      ui_hints: {
        position: 50,
        toggle_role: 'enabled',
        resettable: true,
        composite_fields: [
          { type: 'date_picker', roles: { day: 'onetime_day', month: 'onetime_month', year: 'onetime_year' } }
        ]
      }
    }
  }.freeze
end
