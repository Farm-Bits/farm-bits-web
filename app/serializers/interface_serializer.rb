class InterfaceSerializer < Blueprinter::Base
  identifier :id

  fields :name, :communication_type, :description, :io_number

  field :data_categories do |i|
    i.data_categories
  end

  view :with_measurement_points do
    field :register_mappings do |interface, options|
      plc = options[:plc]
      points = plc.measurement_points.select do |mp|
        mp.register_template.interface_register_mappings.any? { |irm| irm.interface_id == interface.id }
      end.sort_by(&:position)

      interface.interface_register_mappings.map do |irm|
        measurement_point = points.find { |mp| mp.register_template_id == irm.register_template_id }
        {
          register_template: RegisterTemplateSerializer.render_as_json(irm.register_template),
          measurement_point: MeasurementPointSerializer.render_as_json(measurement_point),
          position: irm.position
        }
      end
    end
  end
end
