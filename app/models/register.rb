class Register < ApplicationRecord
  audited

  belongs_to :plc_version

  has_one :interface, dependent: :destroy

  validates :name, presence: true
  validates :address, :inclusion => 0..4294967295
end
