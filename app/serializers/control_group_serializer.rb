class ControlGroupSerializer < Blueprinter::Base
  identifier :id

  fields :name, :icon_key, :position
end
