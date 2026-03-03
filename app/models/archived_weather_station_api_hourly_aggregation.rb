class ArchivedWeatherStationApiHourlyAggregation < ApplicationRecord
  belongs_to :weather_location
  belongs_to :weather_metric
end
