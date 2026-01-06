class MeasurementSubtype < ApplicationRecord
  audited

  belongs_to :measurement_type

  has_many :register_templates, dependent: :restrict_with_error

  DATA_CATEGORIES = %w[status analog counter].freeze
  VALUE_TYPES = %w[accumulative instantaneous status].freeze
  CHART_TYPES = %w[line spline areaspline bar state].freeze
  DEFAULT_AGGREGATION_CONFIGS = {
    accumulative: {
      fields: ['value'],
      hourly: { value: 'SUM(value)' },
      daily: { value: 'SUM(value)' }
    },
    instantaneous: {
      fields: %w[min_value max_value avg_value],
      hourly: {
        min_value: 'MIN(min_value)',
        max_value: 'MAX(max_value)',
        avg_value: 'AVG(avg_value)'
      },
      daily: {
        min_value: 'MIN(min_value)',
        max_value: 'MAX(max_value)',
        avg_value: 'AVG(avg_value)'
      }
    },
    status: {
      fields: %w[state_value state_changed duration_in_state],
      hourly: {
        transition_count: 'COUNT(*) FILTER (WHERE state_changed)',
        duration_state_0: 'SUM(duration_in_state) FILTER (WHERE state_value = 0)',
        duration_state_1: 'SUM(duration_in_state) FILTER (WHERE state_value = 1)',
        last_state: 'LAST_VALUE(state_value)'
      },
      daily: {
        transition_count: 'COUNT(*) FILTER (WHERE state_changed)',
        duration_state_0: 'SUM(duration_in_state) FILTER (WHERE state_value = 0)',
        duration_state_1: 'SUM(duration_in_state) FILTER (WHERE state_value = 1)',
        last_state: 'LAST_VALUE(state_value)'
      }
    }
  }.freeze

  validates :name, presence: true, uniqueness: { scope: :measurement_type_id }
  validates :data_category, presence: true, inclusion: { in: DATA_CATEGORIES }
  validates :value_type, presence: true, inclusion: { in: VALUE_TYPES }
  validates :default_unit, presence: true
  validates :default_chart_type, presence: true, inclusion: { in: CHART_TYPES }
  validates :default_color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: 'must be a valid hex color' }, allow_blank: true

  def full_name
    "#{measurement_type.name} > #{name}"
  end

  def reading_fields
    case value_type
    when 'accumulative'
      [:value]
    when 'instantaneous'
      [:min_value, :max_value, :avg_value]
    when 'status'
      [:state_value, :state_changed, :duration_in_state]
    end
  end

  def aggregation_sql(period = :hourly)
    config = aggregation_config.presence || DEFAULT_AGGREGATION_CONFIGS[value_type.to_sym]
    config[period.to_s] || config[:hourly]
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
