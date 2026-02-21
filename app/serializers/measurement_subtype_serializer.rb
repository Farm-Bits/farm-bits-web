class MeasurementSubtypeSerializer < Blueprinter::Base
  identifier :id

  fields :name,
    :full_name,
    :data_category,
    :value_type,
    :default_unit,
    :default_chart_type,
    :default_color,
    :position

  association :measurement_type, blueprint: MeasurementTypeSerializer
end
