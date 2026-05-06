class SegmentSerializer < Blueprinter::Base
  identifier :id

  fields :name, :position
end
