# Behavior: Sync PLC clock to UTC time.
#
# Register groups:
#   set_system_clock - Time components (seconds, minutes, hours, etc.)
#   time_config      - UTC offset for local time derivation
#
module PlcBehaviors::Concerns::ClockSyncUtc
  extend ActiveSupport::Concern

  TIME_COMPONENT_MAP = {
    'seconds'      => ->(time) { time.sec },
    'minutes'      => ->(time) { time.min },
    'hours'        => ->(time) { time.hour },
    'day_of_week'  => ->(time) { time.wday },
    'day_of_month' => ->(time) { time.day },
    'month'        => ->(time) { time.month },
    'year'         => ->(time) { time.year % 100 }
  }.freeze

  REQUIRED_CLOCK_ROLES = (TIME_COMPONENT_MAP.keys + ['upload_trigger']).freeze

  def sync_clock!
    clock_points = find_group_by_role('set_system_clock')
    if !REQUIRED_CLOCK_ROLES.all? { |role| clock_points.key?(role) }
      Rails.logger.warn(
        "[PlcBehaviors] PLC #{plc.id} missing clock registers, " \
        "found: #{clock_points.keys.sort.join(', ')}"
      )
      return
    end

    utc_time = Time.current.utc
    time_writes = TIME_COMPONENT_MAP.map do |role, value_proc|
      { measurement_point: clock_points[role], value: value_proc.call(utc_time) }
    end

    bulk_write!(time_writes, source: 'system_sync')

    upload_mp = clock_points['upload_trigger']
    single_write!(upload_mp, 1, source: 'system_sync')
  end

  def sync_utc_offset!
    offset_mp = find_group_by_role('time_config')['utc_offset']
    if !offset_mp.present?
      return
    end

    site_tz = plc.site&.time_zone_object || ActiveSupport::TimeZone['UTC']
    offset_minutes = site_tz.utc_offset / 60

    single_write!(offset_mp, offset_minutes, source: 'utc_offset_sync')
  end
end
