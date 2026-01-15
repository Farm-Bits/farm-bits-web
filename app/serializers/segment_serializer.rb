class SegmentSerializer < Blueprinter::Base
  identifier :id

  fields :name, :site_id
end
