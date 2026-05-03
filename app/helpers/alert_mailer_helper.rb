module AlertMailerHelper
  def condition_summary(alert)
    case alert.condition_type
    when 'status_change'
      "Status #{alert.direction.to_s.humanize.downcase}"
    when 'threshold'
      operator = alert.direction == 'above' ? '>' : '<'
      unit     = alert.unit.present? ? " #{alert.unit}" : ''
      "Value #{operator} #{alert.threshold_value}#{unit}"
    when 'inactivity'
      "No data received for #{format_duration(alert.inactivity_seconds)}"
    else
      alert.condition_type
    end
  end

  def format_alert_value(alert, position: :start)
    raw = position == :end ? alert.ended_value : alert.started_value
    if raw.blank?
      return '—'
    end

    if alert.condition_type == 'inactivity'
      return format_duration(raw.to_i)
    end

    unit = alert.unit.present? ? " #{alert.unit}" : ''
    "#{raw}#{unit}"
  end

  def format_duration(seconds)
    seconds = seconds.to_i

    if seconds < 60
      return "#{seconds}s"
    end

    if seconds < 3600
      return "#{seconds / 60}m"
    end

    if seconds < 86400
      hours   = seconds / 3600
      minutes = (seconds % 3600) / 60
      if minutes == 0
        return "#{hours}h"
      end

      return "#{hours}h #{minutes}m"
    end

    days  = seconds / 86400
    hours = (seconds % 86400) / 3600
    if hours == 0
      return "#{days}d"
    end

    "#{days}d #{hours}h"
  end
end
