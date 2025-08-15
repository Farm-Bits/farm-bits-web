class Device < ApplicationRecord
  audited

  belongs_to :device_type
  belongs_to :interface, optional: true

  has_many :measurement_points, dependent: :destroy
  accepts_nested_attributes_for :measurement_points, :allow_destroy => true

  validates :name, presence: true
end
