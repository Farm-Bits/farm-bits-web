class MeasurementSubtype < ApplicationRecord
  audited

  belongs_to :measurement_type

  has_many :device_type_measurement_subtypes, dependent: :destroy
  accepts_nested_attributes_for :device_type_measurement_subtypes, :allow_destroy => true

  class << self
    def value_types
      [
        {
          id: 'Accumulative',
          name: 'Accumulative',
          stream_table_prefix: 'Accum',
          value_query: 'SUM(value) AS value'
        },
        {
          id: 'Instantainus',
          name: 'Instantainus',
          stream_table_prefix: 'Inst',
          value_query: 'MIN(min_value) AS min_value, MAX(max_value) AS max_value, AVG(avg_value) AS avg_value'
        }
      ]
    end

    def chart_types
      [
        { id: 'Line', name: 'Line' },
        { id: 'Spline', name: 'Spline' },
        { id: 'AreaSpline', name: 'AreaSpline' },
        { id: 'Bar', name: 'Bar' }
      ]
    end
  end

  validates :name, presence: true
  validates_inclusion_of :value_type, :in => value_types.map { |m| m[:id] }
  validates_inclusion_of :chart_type, :in => chart_types.map { |m| m[:id] }
  validates :unit, presence: true
end
