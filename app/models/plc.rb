class Plc < ApplicationRecord
  audited

  belongs_to :plc_version
  belongs_to :terminal, optional: true

  validates :name, presence: true
  validates :slave, presence: true
end
