class MeasurementPoint < ApplicationRecord
  audited

  belongs_to :measurement_subtype
  belongs_to :device, optional: true
  belongs_to :segment, optional: true
  belongs_to :site

  validates :name, presence: true
end
