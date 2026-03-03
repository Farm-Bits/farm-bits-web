class HourlyAggregation < ApplicationRecord
  belongs_to :measurement_point

  validates :hour_timestamp, presence: true
  validates :value_type, presence: true, inclusion: { in: MeasurementSubtype::VALUE_TYPES }
  validates :measurement_point_id, uniqueness: { scope: [:date, :hour] }
end
