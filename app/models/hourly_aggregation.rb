class HourlyAggregation < ApplicationRecord
  belongs_to :measurement_point

  validates :date, presence: true
  validates :hour, presence: true, inclusion: { in: 0..23 }
  validates :value_type, presence: true, inclusion: { in: MeasurementSubtype::VALUE_TYPES }
  validates :measurement_point_id, uniqueness: { scope: [:date, :hour] }
end
