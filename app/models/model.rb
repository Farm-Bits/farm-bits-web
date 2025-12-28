class Model < ApplicationRecord
  audited

  belongs_to :manufacturer

  has_many :plc_versions, dependent: :destroy
  accepts_nested_attributes_for :plc_versions, :allow_destroy => true

  has_many :terminals, dependent: :restrict_with_error

  has_many :plcs, dependent: :restrict_with_error

  enum :device_type, {
    terminal: 'terminal',
    plc: 'plc',
    sensor: 'sensor'
  }

  validates :name, presence: true
  validates :name, uniqueness: { scope: :device_type, case_sensitive: false }
  validates :device_type, presence: true

  def full_name
    "#{manufacturer.name} #{name}"
  end
end
