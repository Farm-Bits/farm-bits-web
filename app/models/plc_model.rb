class PlcModel < ApplicationRecord
  audited

  belongs_to :plc_manufacturer

  has_many :plc_versions, dependent: :destroy
  accepts_nested_attributes_for :plc_versions, :allow_destroy => true

  validates :name, presence: true
end
