class TerminalSerializer < Blueprinter::Base
  identifier :id

  fields :label, :name, :imei, :iccid, :phone_number

  view :with_plcs do
    association :plcs, blueprint: PlcSerializer
  end
end
