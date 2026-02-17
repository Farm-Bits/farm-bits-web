# Reusable service to bulk-insert RawValue records and update
# MeasurementPoint#last_decoded_value in a single transaction.
#
# Usage:
#   readings = [
#     { measurement_point_id: 1, value: 42.0, scaled_value: 4.2, sample_time: Time.current },
#     { measurement_point_id: 2, value: 100.0, scaled_value: 10.0, sample_time: Time.current },
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
      # 1. Bulk insert raw values
      RawValue.insert_all(
        @readings.map do |r|
          {
            measurement_point_id: r[:measurement_point_id],
            value: r[:value],
            scaled_value: r[:scaled_value],
            sample_time: r[:sample_time],
            created_at: now
          }
        end
      )

      # 2. Find the latest reading per measurement point and update
      latest_per_mp = @readings
        .group_by { |r| r[:measurement_point_id] }
        .transform_values { |rs| rs.max_by { |r| r[:sample_time] } }

      latest_per_mp.each do |mp_id, reading|
        MeasurementPoint.where(id: mp_id).update_all(
          last_decoded_value: reading[:value],
          last_decoded_value_at: reading[:sample_time],
          updated_at: now
        )
      end
    end

    # TODO: Enqueue threshold check job for affected measurement points
    # ThresholdCheckJob.perform_async(@readings.map { |r| r[:measurement_point_id] }.uniq)
  end
end
