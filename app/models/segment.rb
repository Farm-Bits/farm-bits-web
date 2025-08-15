class Segment < ApplicationRecord
  audited

  belongs_to :site

  has_many :measurement_points, dependent: :destroy

  validates :name, presence: true
end
