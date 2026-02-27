class WeatherStationApiMetricSerializer < Blueprinter::Base
  identifier :id

  fields :key, :label, :measurement_subtype_id

  field :unit do |wsam|
    wsam.effective_unit
  end

  association :measurement_subtype, blueprint: MeasurementSubtypeSerializer
end
