class HourlyAggregation < ApplicationRecord
  belongs_to :measurement_point

  validates :date, presence: true
  validates :hour, presence: true, inclusion: { in: 0..23 }
  validates :value_type, presence: true, inclusion: { in: MeasurementSubtype::VALUE_TYPES }
  validates :measurement_point_id, uniqueness: { scope: [:date, :hour] }

  scope :latest_for_measurement_point, ->(mp_id) {
    where(measurement_point_id: mp_id)
      .order(date: :desc, hour: :desc)
      .limit(1)
  }
end
