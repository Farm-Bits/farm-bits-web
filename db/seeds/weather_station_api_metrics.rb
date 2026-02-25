# Seeds WeatherStationApiMetric records that map IMS channel data to measurement subtypes.
# Run after measurement subtypes are created.
#
# Usage: rails runner db/seeds/weather_station_api_metrics.rb
#
# IMPORTANT: Update measurement_subtype lookups below to match your actual
# MeasurementSubtype records. The subtype_finder hash maps metric keys to
# the criteria used to find the corresponding MeasurementSubtype.

def find_measurement_subtype!(measurement_type_name, name)
  measurement_subtype = MeasurementSubtype
    .joins(:measurement_type)
    .find_by(measurement_types: { name: measurement_type_name }, name: name)

  if measurement_subtype.nil?
    raise "MeasurementSubtype not found: #{measurement_type_name} > #{name}"
  end

  measurement_subtype
end

# Update these lookups to match your actual MeasurementSubtype records.
# Format: metric_key => { measurement_subtype_name: 'MeasurementType name', name: 'MeasurementSubtype name' }
METRIC_DEFINITIONS = [
  {
    key: 'temperature',
    label: 'Temperature',
    unit: '°C',
    factor: 1.0,
    offset: 0.0,
    aggregation: 'avg',
    measurement_subtype: { measurement_type_name: 'Weather', name: 'Temperature' }
  },
  {
    key: 'humidity',
    label: 'Humidity',
    unit: '%',
    factor: 1.0,
    offset: 0.0,
    aggregation: 'avg',
    measurement_subtype: { measurement_type_name: 'Weather', name: 'Humidity' }
  },
  {
    key: 'precipitation',
    label: 'Precipitation',
    unit: 'mm',
    factor: 1.0,
    offset: 0.0,
    aggregation: 'sum',
    measurement_subtype: { measurement_type_name: 'Weather', name: 'Precipitation' }
  },
  {
    key: 'wind_speed',
    label: 'Wind Speed',
    unit: 'm/s',
    factor: 1.0,
    offset: 0.0,
    aggregation: 'avg',
    measurement_subtype: { measurement_type_name: 'Weather', name: 'Wind Speed' }
  },
  {
    key: 'wind_direction',
    label: 'Wind Direction',
    unit: '°',
    factor: 1.0,
    offset: 0.0,
    aggregation: 'avg',
    measurement_subtype: { measurement_type_name: 'Weather', name: 'Wind Direction' }
  },
  {
    key: 'barometric_pressure',
    label: 'Barometric Pressure',
    unit: 'mb',
    factor: 1.0,
    offset: 0.0,
    aggregation: 'avg',
    measurement_subtype: { measurement_type_name: 'Weather', name: 'Barometric Pressure' }
  },
  {
    key: 'global_radiation',
    label: 'Global Radiation',
    unit: 'W/m²',
    factor: 1.0,
    offset: 0.0,
    aggregation: 'avg',
    measurement_subtype: { measurement_type_name: 'Weather', name: 'Global Radiation' }
  },
  {
    key: 'direct_radiation',
    label: 'Direct Radiation',
    unit: 'W/m²',
    factor: 1.0,
    offset: 0.0,
    aggregation: 'avg',
    measurement_subtype: { measurement_type_name: 'Weather', name: 'Direct Radiation' }
  },
  {
    key: 'diffused_radiation',
    label: 'Diffused Radiation',
    unit: 'W/m²',
    factor: 1.0,
    offset: 0.0,
    aggregation: 'avg',
    measurement_subtype: { measurement_type_name: 'Weather', name: 'Diffused Radiation' }
  }
].freeze

puts "Seeding WeatherStationApiMetrics..."

ActiveRecord::Base.transaction do
  METRIC_DEFINITIONS.each do |defn|
    measurement_subtype = find_measurement_subtype!(defn[:measurement_subtype][:measurement_type_name], defn[:measurement_subtype][:name])

    metric = WeatherStationApiMetric.find_or_initialize_by(key: defn[:key])
    metric.assign_attributes(
      label: defn[:label],
      unit: defn[:unit],
      factor: defn[:factor],
      offset: defn[:offset],
      aggregation: defn[:aggregation],
      measurement_subtype: measurement_subtype
    )

    if metric.new_record?
      metric.save!
      puts "  Created: #{metric.key} → #{measurement_subtype.measurement_type.name} > #{measurement_subtype.name}"
    elsif metric.changed?
      metric.save!
      puts "  Updated: #{metric.key}"
    else
      puts "  Unchanged: #{metric.key}"
    end
  end
end

puts "Done. #{WeatherStationApiMetric.count} weather metrics total."
