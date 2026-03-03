class WeatherStationApiHourlyAggregation < ApplicationRecord
  belongs_to :weather_station_api_location
  belongs_to :weather_station_api_metric

  validates :hour_timestamp, presence: true
  validates :sample_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
