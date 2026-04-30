class ArchivedModbusWriteLog < ApplicationRecord
  belongs_to :target, polymorphic: true
  belongs_to :relay_host_plc, class_name: 'Plc', optional: true
  belongs_to :site
  belongs_to :user, optional: true
  belongs_to :measurement_point
  belongs_to :register_template
end
