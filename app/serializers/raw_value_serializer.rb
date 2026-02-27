class RawValueSerializer < Blueprinter::Base
  identifier :id

  fields :sample_time, :measurement_point_id

  field :value do |rv|
    rv.scaled_value&.to_f
  end
end
