class WeatherStationApiMetric < ApplicationRecord
  audited

  belongs_to :measurement_subtype

  has_many :weather_station_api_raw_values, dependent: :destroy

  has_many :weather_station_api_hourly_aggregations, dependent: :destroy

  validates :key, presence: true, uniqueness: true
  validates :label, presence: true
  validates :unit, presence: true
  validates :factor, presence: true, numericality: true
  validates :offset, presence: true, numericality: true

  def effective_unit
    unit.presence || measurement_subtype&.default_unit
  end

  def scale_value(raw_value)
    if raw_value.nil?
      return nil
    end

    (raw_value.to_d * factor) + offset
  end

  def reverse_scaled(scaled_value)
    if scaled_value.nil?
      return nil
    end

    if factor.zero?
      return nil
    end

    (scaled_value.to_d - offset) / factor
  end
end
