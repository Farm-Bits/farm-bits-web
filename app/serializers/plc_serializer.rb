class PlcSerializer < Blueprinter::Base
  identifier :id

  fields :label, :name, :slave, :private_ip, :last_seen_at

  association :plc_version, blueprint: PlcVersionSerializer

  view :with_interfaces do
    field :interfaces do |plc|
      InterfaceSerializer.render_as_json(
        plc.plc_version.interfaces,
        view: :with_measurement_points,
        plc: plc
      )
    end

    field :register_mappings do |plc|
      non_interface_measurement_points = plc.measurement_points.select do |mp|
        !mp.register_template.interface_register_mappings.any?
      end.sort_by(&:position)

      non_interface_measurement_points.map do |mp|
        {
          register_template: RegisterTemplateSerializer.render_as_json(mp.register_template),
          measurement_point: MeasurementPointSerializer.render_as_json(mp),
          position: mp.position
        }
      end
    end
  end
end
