class RawValue < ApplicationRecord
  self.record_timestamps = false

  belongs_to :measurement_point

  validates :value, presence: true
  validates :scaled_value, presence: true
  validates :sample_time, presence: true

  before_create { self.created_at = Time.current }
end
