class SiteSunDataSerializer < Blueprinter::Base
  identifier :id

  fields :date, :day_length_seconds

  field :sunrise do |ssd|
    ssd.sunrise&.strftime("%H:%M:%S")
  end

  field :sunset do |ssd|
    ssd.sunset&.strftime("%H:%M:%S")
  end

  field :civil_twilight_begin do |ssd|
    ssd.civil_twilight_begin&.strftime("%H:%M:%S")
  end

  field :civil_twilight_end do |ssd|
    ssd.civil_twilight_end&.strftime("%H:%M:%S")
  end
end
