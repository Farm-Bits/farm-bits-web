class PlcVersionSerializer < Blueprinter::Base
  identifier :id

  fields :name, :description, :is_latest, :is_supported
end
