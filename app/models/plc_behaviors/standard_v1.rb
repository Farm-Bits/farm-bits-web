class PlcBehaviors::StandardV1 < PlcBehaviors::Base
  include PlcBehaviors::Concerns::ClockSyncUtc             # sync_clock!, sync_utc_offset!
  include PlcBehaviors::Concerns::IoActive                 # sync_io_active!
  include PlcBehaviors::Concerns::SunDataSync              # sync_sun_data!
  include PlcBehaviors::Concerns::SensorCascade            # cascade_sensor_deactivation!
  include PlcBehaviors::Concerns::OnetimeScheduleCleanup   # cleanup_onetime_schedules!
  include PlcBehaviors::Concerns::SensorConditionScaling   # pre_write_transforms

  SYSTEM_GROUPS = {

    # ── System ────────────────────────────────────────────

    'set_system_clock' => {
      description: 'PLC clock registers (UTC)',
      roles: %w[seconds minutes hours day_of_week day_of_month month year upload_trigger],
    },
    'time_config' => {
      description: 'UTC offset for local time derivation',
      roles: %w[utc_offset],
    },
    'sun_data' => {
      description: 'Sunrise/sunset in local minutes-since-midnight',
      roles: %w[sunrise sunset],
    },
    'smtp_push_data' => {
      description: 'SMTP credentials for push data emails',
      roles: %w[hostname port username password to_email],
    },
    'io_active' => {
      description: 'IO active booleans. One per interface.',
      roles: %w[active_ai_* active_di_* active_do_* active_ao_*],
    },
    'push_data_thresholds' => {
      description: 'Per-IO push data change thresholds',
      roles: %w[threshold_ai_* threshold_di_counter_*],
    },
    'io_health' => {
      description: 'Configurable error detection per input interface',
      roles: %w[detect_mode detect_value_1 detect_value_2 health_status],
    },

    # ── Operation Mode (per digital output interface) ─────

    'om_status' => {
      description: 'Read-only status: active source, error flags, countdown',
      roles: %w[active_source error_flags next_change_time],
    },
    'om_manual' => {
      description: 'Manual ON/OFF control with optional timed duration',
      roles: %w[command duration],
    },
    'om_duty_cycle' => {
      description: 'Standalone duty cycle: repeating ON/OFF phases',
      roles: %w[enabled on_duration off_duration],
    },
    'om_sensor' => {
      description: 'Sensor trigger master enable',
      roles: %w[enabled],
    },
    'om_sensor_cond_*' => {
      description: 'Individual sensor conditions with source reference',
      roles: %w[enabled source_type source_io_number operator threshold hysteresis],
    },
    'om_schedule_*' => {
      description: 'Schedule slots: recurring weekly or one-time',
      roles: %w[
        enabled action start_ref start_time start_offset duration
        dc_on_duration dc_off_duration schedule_type days
        onetime_day onetime_month onetime_year
      ],
    },
    'om_window' => {
      description: 'Time window: output can only be ON during this window',
      roles: %w[enabled start_ref start_time start_offset end_ref end_time end_offset days],
    },
    'om_safety' => {
      description: 'Safety constraints: emergency stop, max on, min off/on',
      roles: %w[emergency_stop max_on_enabled max_on min_off_enabled min_off min_on_enabled min_on],
    },

  }.freeze
end
