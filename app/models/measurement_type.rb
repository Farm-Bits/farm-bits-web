class MeasurementType < ApplicationRecord
  audited

  has_many :measurement_subtypes, dependent: :destroy
  accepts_nested_attributes_for :measurement_subtypes, :allow_destroy => true

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
