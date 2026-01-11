class MeasurementTypeSerializer < Blueprinter::Base
  identifier :id

  fields :name, :position
end
