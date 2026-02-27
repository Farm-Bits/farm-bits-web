class WeatherRawValueSerializer < Blueprinter::Base
  identifier :id

  fields :sample_time

  field :value do |rv|
    rv.scaled_value&.to_f
  end
end
