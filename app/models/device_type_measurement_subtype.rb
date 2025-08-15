class DeviceTypeMeasurementSubtype < ApplicationRecord
  audited

  belongs_to :device_type
  belongs_to :measurement_subtype
end
