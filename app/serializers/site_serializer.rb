class SiteSerializer < Blueprinter::Base
  identifier :id

  fields :name, :country, :city, :latitude, :longitude, :altitude, :time_zone

  view :with_segments do
    association :segments, blueprint: SegmentSerializer
  end
end
