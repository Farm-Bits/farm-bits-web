class ModelSerializer < Blueprinter::Base
  identifier :id

  fields :name, :full_name, :display_type, :device_type

  association :manufacturer, blueprint: ManufacturerSerializer
end
