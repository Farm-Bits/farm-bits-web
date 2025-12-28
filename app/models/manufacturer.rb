class Manufacturer < ApplicationRecord
  audited

  has_many :models, dependent: :destroy
  accepts_nested_attributes_for :models, :allow_destroy => true

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
