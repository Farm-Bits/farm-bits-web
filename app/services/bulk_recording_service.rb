# Service to bulk-insert RawValue records and update
# MeasurementPoint#last_decoded_value in a single transaction.
#
# Used after reading registers from PLCs (via polling or manual read).
# Values should be already decoded (via RegisterTemplate#decode_data)
# but NOT yet transformed (factor/offset is applied at display time).
#
# Usage:
#   readings = [
#     { measurement_point: mp1, value: 250, sample_time: Time.current },
#     { measurement_point: mp2, value: 1,   sample_time: Time.current },
#   ]
#   BulkRecordingService.new(readings).call
#
class BulkRecordingService
  def initialize(readings)
    @readings = readings
  end

  def call
    if @readings.empty?
      return
    end

    now = Time.current

    transitions = capture_value_transitions

    ApplicationRecord.transaction do
      active_readings = @readings.select { |r| r[:measurement_point].active }

      if active_readings.any?
        raw_value_rows = active_readings.map do |r|
          measurement_point = r[:measurement_point]
          scaled_value = measurement_point.scale_decoded_value(r[:value])

          {
            measurement_point_id: measurement_point.id,
            value: r[:value],
            scaled_value: scaled_value,
            sample_time: r[:sample_time],
            created_at: now
          }
        end
        RawValue.insert_all(raw_value_rows)
      end

      latest_per_mp = @readings
        .group_by { |r| r[:measurement_point].id }
        .transform_values { |rs| rs.max_by { |r| r[:sample_time] } }

      if latest_per_mp.empty?
        return
      end

      mp_ids = latest_per_mp.keys

      value_cases = latest_per_mp.map do |mp_id, reading|
        serialized = reading[:measurement_point].serialize_for_storage(reading[:value])
        "WHEN #{mp_id.to_i} THEN #{ActiveRecord::Base.connection.quote(serialized)}"
      end.join(' ')

      time_cases = latest_per_mp.map do |mp_id, reading|
        "WHEN #{mp_id.to_i} THEN #{ActiveRecord::Base.connection.quote(reading[:sample_time])}"
      end.join(' ')

      MeasurementPoint.where(id: mp_ids).update_all(
        "last_decoded_value = CASE id #{value_cases} END, " \
        "last_decoded_value_at = CASE id #{time_cases} END, " \
        "updated_at = #{ActiveRecord::Base.connection.quote(now)}"
      )
    end

    touch_devices!
    enqueue_alert_evaluations(transitions)
  end

  private
    # Build [{mp_id, old_value, new_value, sample_time}] tuples from the
    # latest reading per MP. Old values come from the in-memory MPs
    # before update_all overwrites them. Tuples where old == new are
    # dropped - threshold/status_change predicates can't trigger without
    # a transition, and inactivity is handled by the cron scanner.
    def capture_value_transitions
      latest_per_mp = @readings
        .group_by { |r| r[:measurement_point].id }
        .transform_values { |rs| rs.max_by { |r| r[:sample_time] } }

      latest_per_mp.filter_map do |mp_id, reading|
        mp        = reading[:measurement_point]
        new_value = mp.serialize_for_storage(reading[:value])
        old_value = mp.last_decoded_value

        if old_value == new_value
          next
        end

        {
          mp_id:       mp_id,
          old_value:   old_value,
          new_value:   new_value,
          sample_time: reading[:sample_time]
        }
      end
    end

    def enqueue_alert_evaluations(transitions)
      transitions.each do |t|
        AlertEvaluationJob.perform_async(
          t[:mp_id],
          t[:old_value],
          t[:new_value],
          t[:sample_time].iso8601
        )
      end
    end

    def touch_devices!
      plc_ids           = @readings.map { |r| r[:measurement_point].plc_id }.compact.uniq
      modbus_device_ids = @readings.map { |r| r[:measurement_point].modbus_device_id }.compact.uniq

      if plc_ids.any?
        Plc.where(id: plc_ids).update_all(last_seen_at: Time.current)
      end

      if modbus_device_ids.any?
        ModbusDevice.where(id: modbus_device_ids).update_all(last_seen_at: Time.current)
      end

      gateway_ids_from_plcs    = Plc.where(id: plc_ids).pluck(:gateway_id)
      gateway_ids_from_devices = ModbusDevice.where(id: modbus_device_ids).pluck(:gateway_id)
      gateway_ids = (gateway_ids_from_plcs + gateway_ids_from_devices).compact.uniq

      if gateway_ids.any?
        Gateway.where(id: gateway_ids).update_all(last_seen_at: Time.current)
      end
    end
end
