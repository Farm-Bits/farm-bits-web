# Behavior: Daily cleanup of expired one-time schedule slots
# and one-time time windows.
#
# The backend is the source of truth for configuration. It knows the
# full date (year + month + day) of every one-time event and can
# determine if it has passed without reading from the PLC.
#
# SCHEDULE SLOTS (om_schedule_*):
#   A one-time slot has onetime_month > 0 and onetime_year > 0.
#   The backend builds the full date from onetime_year/month/day
#   and compares against today. If the date has passed, all fields
#   in the slot are cleared to free it for reuse.
#
# TIME WINDOWS (om_duty_cycle_window, om_sensor_window):
#   A one-time window has onetime_date > 0 (encoded as month×100+day).
#   These don't have a year register — the PLC handles expiry by
#   clearing onetime_date after the window passes.
#
module PlcBehaviors::Concerns::OnetimeScheduleCleanup
  extend ActiveSupport::Concern

  def cleanup_onetime_schedules!
    cleanup_expired_schedule_slots!
  end

  private
    def cleanup_expired_schedule_slots!
      schedule_points = find_group_pattern('om_schedule_*')
        .to_a
        .group_by { |mp| mp.register_template.group_name }

      writes = []
      cleared_count = 0

      schedule_points.each do |_group_name, points|
        points_by_role = points.index_by { |mp| mp.register_template.group_role }

        onetime_month_mp = points_by_role['onetime_month']
        onetime_year_mp = points_by_role['onetime_year']
        if !onetime_month_mp.present? || !onetime_year_mp.present?
          next
        end

        year_val = onetime_year_mp.last_decoded_value&.to_i || 0
        month_val = onetime_month_mp.last_decoded_value&.to_i || 0

        # Not a one-time slot (recurring or empty)
        if year_val != 0 && month_val != 0
          day_val = points_by_role['onetime_day']&.last_decoded_value&.to_i || 1

          # Build the event date and check if it has passed
          if !event_date_has_passed?(year_val, month_val, day_val)
            next
          end
        end

        # Event date has passed — clear all fields in this slot
        points.each do |mp|
          writes << { measurement_point: mp, value: 0 }
        end

        cleared_count += 1
      end

      if writes.any?
        bulk_write!(writes, source: 'onetime_cleanup')
      end
    end

    def event_date_has_passed?(year, month, day)
      begin
        event_date = Date.new(year, month, day)
      rescue ArgumentError
        # Invalid date (e.g., Feb 30) — treat as expired
        return true
      end

      event_date < Date.current
    end
end
