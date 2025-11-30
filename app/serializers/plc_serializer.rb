class PlcSerializer < Blueprinter::Base
  identifier :id

  fields :label, :name, :slave

  association :plc_version, blueprint: PlcVersionSerializer
end
