class MeasurementSubtype < ApplicationRecord
  audited

  belongs_to :measurement_type

  has_many :register_templates, dependent: :restrict_with_error

  DATA_CATEGORIES = %w[status analog counter].freeze
  VALUE_TYPES = %w[accumulative instantaneous status].freeze
  CHART_TYPES = %w[line area bar state rangeBar].freeze

  validates :name, presence: true, uniqueness: { scope: :measurement_type_id }
  validates :data_category, presence: true, inclusion: { in: DATA_CATEGORIES }
  validates :value_type, presence: true, inclusion: { in: VALUE_TYPES }
  validates :default_unit, presence: true
  validates :default_chart_type, presence: true, inclusion: { in: CHART_TYPES }
  validates :default_color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: 'must be a valid hex color' }, allow_blank: true

  def full_name
    "#{measurement_type.name} > #{name}"
  end

  def effective_chart_type
    if default_chart_type.present?
      return default_chart_type
    end

    case value_type
    when 'accumulative' then 'bar'
    when 'instantaneous' then 'line'
    when 'status' then 'state'
    end
  end
end
