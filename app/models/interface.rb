class Interface < ApplicationRecord
  audited

  belongs_to :plc_version

  has_many :register_templates, dependent: :destroy
  accepts_nested_attributes_for :register_templates, :allow_destroy => true

  COMMUNICATION_TYPES = %w[analog_input analog_output digital_input digital_output].freeze

  validates :name, presence: true, uniqueness: { scope: :plc_version_id }
  validates :communication_type, presence: true, inclusion: { in: COMMUNICATION_TYPES }

  def input?
    communication_type.end_with?('_input')
  end

  def output?
    communication_type.end_with?('_output')
  end
end
