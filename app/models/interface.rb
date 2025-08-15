class Interface < ApplicationRecord
  audited

  belongs_to :register
  belongs_to :plc_version

  has_one :device, dependent: :destroy

  has_many :interface_registers, dependent: :destroy
  has_many :registers, through: :interface_registers
  accepts_nested_attributes_for :interface_registers, :allow_destroy => true

  class << self
    def communication_types
      [
        { id: 'DI', name: 'Digital Input' },
        { id: 'DO', name: 'Digital Output' },
        { id: 'AI', name: 'Analog Input' },
        { id: 'AO', name: 'Analog Output' }
      ]
    end
  end

  validates :name, presence: true
  validates_inclusion_of :communication_type, :in => communication_types.map { |s| s[:id] }
end
