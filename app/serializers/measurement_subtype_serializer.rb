class MeasurementSubtypeSerializer < Blueprinter::Base
  identifier :id

  fields :name,
    :data_category,
    :value_type,
    :default_unit,
    :default_chart_type,
    :default_color

  field :full_name do |ms|
    ms.full_name
  end

  association :measurement_type, blueprint: MeasurementTypeSerializer
end
