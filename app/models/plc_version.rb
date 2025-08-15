class PlcVersion < ApplicationRecord
  audited

  belongs_to :plc_model
  belongs_to :plc_version, optional: true

  has_many :plc_versions, dependent: :destroy
  accepts_nested_attributes_for :plc_versions, :allow_destroy => true

  has_many :interfaces, dependent: :destroy
  accepts_nested_attributes_for :interfaces, :allow_destroy => true

  has_many :registers, dependent: :destroy
  accepts_nested_attributes_for :registers, :allow_destroy => true

  validates :name, presence: true
end
