class DeviceType < ApplicationRecord
  audited

  has_many :device_type_measurement_subtypes, dependent: :destroy
  accepts_nested_attributes_for :device_type_measurement_subtypes, :allow_destroy => true

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates_inclusion_of :communication_type, :in => Interface.communication_types.map { |s| s[:id] }
end
