class RawValue < ApplicationRecord
  belongs_to :measurement_point

  validates :value, presence: true
  validates :scaled_value, presence: true
  validates :sample_time, presence: true

  scope :latest_for_measurement_point, ->(mp_id) {
    where(measurement_point_id: mp_id)
      .order(sample_time: :desc)
      .limit(1)
  }

  self.record_timestamps = false
  before_create { self.created_at = Time.current }
end
