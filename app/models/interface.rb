class Interface < ApplicationRecord
  audited

  belongs_to :plc_version

  has_many :interface_register_mappings, dependent: :destroy
  has_many :register_templates, through: :interface_register_mappings

  COMMUNICATION_TYPES = %w[analog_input analog_output digital_input digital_output].freeze
  CATEGORIES = (MeasurementSubtype::DATA_CATEGORIES + %w[interface_configuration measurement_point_configuration operation_mode_configuration]).freeze

  validates :name, presence: true, uniqueness: { scope: :plc_version_id }
  validates :communication_type, presence: true, inclusion: { in: COMMUNICATION_TYPES }
  validates :io_number, presence: true, numericality: { only_integer: true, greater_than: 0 }

  def analog?
    communication_type.start_with?('analog_')
  end

  def digital?
    communication_type.start_with?('digital_')
  end

  def input?
    communication_type.end_with?('_input')
  end

  def output?
    communication_type.end_with?('_output')
  end

  def data_categories
    case communication_type
    when 'digital_input'
      ['status', 'counter']
    when 'digital_output'
      ['status']
    when 'analog_input'
      ['analog', 'counter']
    when 'analog_output'
      ['analog']
    end
  end

  def register_template_for_category(category)
    interface_register_mappings.find_by(data_category: category)&.register_template
  end

  def category_configured?(category)
    register_template_for_category(category).present?
  end

  def configured_categories
    interface_register_mappings.pluck(:data_category)
  end

  def available_categories
    data_categories - configured_categories
  end
end
