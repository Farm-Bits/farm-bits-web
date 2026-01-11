class PlcSerializer < Blueprinter::Base
  identifier :id

  fields :label, :name, :slave, :private_ip, :last_seen_at

  association :plc_version, blueprint: PlcVersionSerializer

  view :with_interfaces do
    field :interfaces do |plc|
      InterfaceSerializer.render_as_hash(
        plc.plc_version.interfaces,
        view: :with_measurement_points,
        plc: plc
      )
    end
  end
end
