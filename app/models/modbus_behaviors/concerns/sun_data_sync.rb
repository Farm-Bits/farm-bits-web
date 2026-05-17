# Behavior: Write daily sunrise/sunset to PLC registers.
#
# Register group:
#   sun_data - sunrise and sunset in local minutes-since-midnight
#
module ModbusBehaviors::Concerns::SunDataSync
  extend ActiveSupport::Concern

  def sync_sun_data!(sunrise_minutes, sunset_minutes)
    sun_points = find_group_by_role('sun_data')

    sunrise_mp = sun_points['sunrise']
    sunset_mp = sun_points['sunset']
    if !sunrise_mp.present? || !sunset_mp.present?
      return
    end

    writes = [
      { measurement_point: sunrise_mp, value: sunrise_minutes },
      { measurement_point: sunset_mp, value: sunset_minutes }
    ]

    bulk_write!(writes, source: 'sun_data_sync')
  end
end
