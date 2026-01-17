class SiteSerializer < Blueprinter::Base
  identifier :id

  fields :name, :country, :city, :latitude, :longitude, :altitude, :time_zone
end
