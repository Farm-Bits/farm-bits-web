class Terminal < ApplicationRecord
  audited

  belongs_to :terminal_model
  belongs_to :site

  has_many :plcs, dependent: :destroy
  accepts_nested_attributes_for :plcs, :allow_destroy => true

  validates :imei, presence: true, uniqueness: { case_sensitive: false }
  validates :iccid, presence: true, uniqueness: { case_sensitive: false }
  validates :phone_number, presence: true, uniqueness: { case_sensitive: false }
end
