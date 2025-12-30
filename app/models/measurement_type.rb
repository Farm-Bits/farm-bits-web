class MeasurementType < ApplicationRecord
  audited

  has_many :measurement_subtypes, dependent: :destroy
  accepts_nested_attributes_for :measurement_subtypes, :allow_destroy => true

  CATEGORIES = %w[sensor control].freeze

  validates :name, presence: true, uniqueness: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
end
