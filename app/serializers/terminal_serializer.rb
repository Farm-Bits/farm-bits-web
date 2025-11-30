class TerminalSerializer < Blueprinter::Base
  identifier :id

  fields :label, :name, :imei, :iccid, :phone_number

  view :with_plcs do
    association :plcs, blueprint: PlcSerializer do |terminal|
      terminal.plcs.includes(:plc_version)
    end
  end
end
