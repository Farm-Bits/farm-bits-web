class WeatherStationApiRawValue < ApplicationRecord
  self.record_timestamps = false

  belongs_to :weather_station_api_location
  belongs_to :weather_station_api_metric

  validates :value, presence: true, numericality: true
  validates :scaled_value, presence: true, numericality: true
  validates :sample_time, presence: true
end
