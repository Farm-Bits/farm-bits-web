class RawValue < ApplicationRecord
  belongs_to :measurement_point

  validates :value, presence: true
  validates :scaled_value, presence: true
  validates :sample_time, presence: true

  self.record_timestamps = false
  before_create { self.created_at = Time.current }
end
