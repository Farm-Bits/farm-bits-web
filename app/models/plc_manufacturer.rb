class PlcManufacturer < ApplicationRecord
  audited

  has_many :plc_models, dependent: :destroy
  accepts_nested_attributes_for :plc_models, :allow_destroy => true

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
