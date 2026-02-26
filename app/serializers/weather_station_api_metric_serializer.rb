class WeatherStationApiMetricSerializer < Blueprinter::Base
  identifier :id

  fields :key, :label, :effective_unit, :aggregation, :measurement_subtype_id

  association :measurement_subtype, blueprint: MeasurementSubtypeSerializer
end
