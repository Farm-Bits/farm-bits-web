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

      latest_per_mp.each do |mp_id, reading|
        measurement_point = reading[:measurement_point]

        MeasurementPoint.where(id: mp_id).update_all(
          last_decoded_value: measurement_point.serialize_for_storage(reading[:value]),
          last_decoded_value_at: reading[:sample_time],
          updated_at: now
        )
      end
    end

    touch_devices!
  end

  private
    def touch_devices!
      plc_ids = @readings.map { |r| r[:measurement_point].plc_id }.uniq
      Plc.where(id: plc_ids).update_all(last_seen_at: Time.current)
      Gateway.joins(:plcs).where(plcs: { id: plc_ids }).update_all(last_seen_at: Time.current)
    end
end
