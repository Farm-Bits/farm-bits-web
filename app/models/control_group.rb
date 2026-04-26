class ControlGroup < ApplicationRecord
  audited
  has_many :measurement_subtypes

  validates :name, presence: true
  validates :position, presence: true
end
