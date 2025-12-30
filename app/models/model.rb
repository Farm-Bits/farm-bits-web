class Model < ApplicationRecord
  audited

  belongs_to :manufacturer

  has_many :plc_versions, dependent: :destroy
  accepts_nested_attributes_for :plc_versions, :allow_destroy => true

  has_many :terminals, dependent: :restrict_with_error

  has_many :plcs, dependent: :restrict_with_error

  DEVICE_TYPES = %w[terminal plc sensor control].freeze

  validates :name, presence: true, uniqueness: { scope: :manufacturer_id }
  validates :device_type, presence: true, inclusion: { in: DEVICE_TYPES }

  def full_name
    "#{manufacturer.name} #{name}"
  end
end
