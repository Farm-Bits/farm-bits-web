# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

ActiveRecord::Base.transaction do
  AdminUser.create!(
    name: 'Jeremy Khalfa',
    email: 'jeremy@farm-bits.com',
    password: 'Jeremy123',
    password_confirmation: 'Jeremy123'
  )

  MeasurementType.create!([
    {
      name: 'Weather',
      position: 1,
      measurement_subtypes_attributes: [
        { name: 'Temperature',         data_category: 'analog',  value_type: 'instantaneous', default_unit: '°C',    default_chart_type: 'line', default_color: '#FF8C00', icon_key: 'temperature', position: 1 },
        { name: 'Humidity',            data_category: 'analog',  value_type: 'instantaneous', default_unit: '%',     default_chart_type: 'line', default_color: '#39A0CA', icon_key: 'humidity', position: 2 },
        { name: 'Wind Speed',          data_category: 'analog',  value_type: 'instantaneous', default_unit: 'm/s',   default_chart_type: 'line', default_color: '#00008B', position: 3 },
        { name: 'Wind Direction',      data_category: 'analog',  value_type: 'instantaneous', default_unit: '°',     default_chart_type: 'line', default_color: '#4682B4', position: 4 },
        { name: 'Precipitation',       data_category: 'counter', value_type: 'accumulative',  default_unit: 'mm',    default_chart_type: 'bar',  default_color: '#1E90FF', position: 5 },
        { name: 'Precipitation Rate',  data_category: 'analog',  value_type: 'instantaneous', default_unit: 'mm/hr', default_chart_type: 'line', default_color: '#1E90FF', position: 6 },
        { name: 'Global Radiation',    data_category: 'analog',  value_type: 'instantaneous', default_unit: 'W/m²',  default_chart_type: 'line', default_color: '#FFD700', position: 7 },
        { name: 'Direct Radiation',    data_category: 'analog',  value_type: 'instantaneous', default_unit: 'W/m²',  default_chart_type: 'line', default_color: '#FFA500', position: 8 },
        { name: 'Diffused Radiation',  data_category: 'analog',  value_type: 'instantaneous', default_unit: 'W/m²',  default_chart_type: 'line', default_color: '#FFDAB9', position: 9 },
        { name: 'Barometric Pressure', data_category: 'analog',  value_type: 'instantaneous', default_unit: 'hPa',   default_chart_type: 'line', default_color: '#708090', position: 10 },
        { name: 'Leaf Wetness',        data_category: 'analog',  value_type: 'instantaneous', default_unit: '%',     default_chart_type: 'line', default_color: '#32CD32', position: 11 },
        { name: 'Dew Point',           data_category: 'analog',  value_type: 'instantaneous', default_unit: '°C',    default_chart_type: 'line', default_color: '#87CEEB', position: 12 }
      ]
    },
    {
      name: 'Ambient',
      position: 2,
      measurement_subtypes_attributes: [
        { name: 'Temperature',         data_category: 'analog', value_type: 'instantaneous', default_unit: '°C',       default_chart_type: 'line', default_color: '#FF8C00', icon_key: 'temperature', position: 1 },
        { name: 'Humidity',            data_category: 'analog', value_type: 'instantaneous', default_unit: '%',        default_chart_type: 'line', default_color: '#39A0CA', icon_key: 'humidity', position: 2 },
        { name: 'CO2',                 data_category: 'analog', value_type: 'instantaneous', default_unit: 'ppm',      default_chart_type: 'line', default_color: '#A9A9A9', position: 3 },
        { name: 'Light Level',         data_category: 'analog', value_type: 'instantaneous', default_unit: 'µmol/m²s', default_chart_type: 'line', default_color: '#FFD700', position: 4 },
        { name: 'Light Integral',      data_category: 'analog', value_type: 'accumulative',  default_unit: 'mol/m²',   default_chart_type: 'bar',  default_color: '#FFD700', position: 5 }
      ]
    },
    {
      name: 'Soil',
      position: 3,
      measurement_subtypes_attributes: [
        { name: 'Temperature',         data_category: 'analog', value_type: 'instantaneous', default_unit: '°C',    default_chart_type: 'line', default_color: '#FF8C00', icon_key: 'temperature', position: 1 },
        { name: 'Moisture',            data_category: 'analog', value_type: 'instantaneous', default_unit: '%',     default_chart_type: 'line', default_color: '#39A0CA', position: 2 },
        { name: 'Water Tension',       data_category: 'analog', value_type: 'instantaneous', default_unit: 'kPa',   default_chart_type: 'line', default_color: '#6B8E23', position: 3 },
        { name: 'EC',                  data_category: 'analog', value_type: 'instantaneous', default_unit: 'dS/m',  default_chart_type: 'line', default_color: '#DAA520', position: 4 },
        { name: 'pH',                  data_category: 'analog', value_type: 'instantaneous', default_unit: 'pH',    default_chart_type: 'line', default_color: '#9370DB', position: 5 },
      ]
    },
    {
      name: 'Water Quality',
      position: 4,
      measurement_subtypes_attributes: [
        { name: 'EC',                  data_category: 'analog', value_type: 'instantaneous', default_unit: 'dS/m',  default_chart_type: 'line', default_color: '#DAA520', position: 1 },
        { name: 'pH',                  data_category: 'analog', value_type: 'instantaneous', default_unit: 'pH',    default_chart_type: 'line', default_color: '#9370DB', position: 2 },
        { name: 'Temperature',         data_category: 'analog', value_type: 'instantaneous', default_unit: '°C',    default_chart_type: 'line', default_color: '#FF8C00', icon_key: 'temperature', position: 3 },
        { name: 'Dissolved Oxygen',    data_category: 'analog', value_type: 'instantaneous', default_unit: 'mg/L',  default_chart_type: 'line', default_color: '#00CED1', position: 4 },
        { name: 'Turbidity',           data_category: 'analog', value_type: 'instantaneous', default_unit: 'NTU',   default_chart_type: 'line', default_color: '#D2B48C', position: 5 }
      ]
    },
    {
      name: 'Electricity',
      position: 5,
      measurement_subtypes_attributes: [
        { name: 'Power',               data_category: 'analog',  value_type: 'instantaneous', default_unit: 'W',    default_chart_type: 'line', default_color: '#FFD700', position: 1 },
        { name: 'Energy',              data_category: 'counter', value_type: 'accumulative',  default_unit: 'Wh',   default_chart_type: 'bar',  default_color: '#FFA500', position: 2 },
        { name: 'Energy Meter',        data_category: 'analog',  value_type: 'accumulative',  default_unit: 'Wh',   default_chart_type: 'bar',  default_color: '#FFA500', position: 3 },
        { name: 'Voltage',             data_category: 'analog',  value_type: 'instantaneous', default_unit: 'V',    default_chart_type: 'line', default_color: '#0D6EFD', position: 4 },
        { name: 'Current',             data_category: 'analog',  value_type: 'instantaneous', default_unit: 'A',    default_chart_type: 'line', default_color: '#DC3545', position: 5 },
        { name: 'Frequency',           data_category: 'analog',  value_type: 'instantaneous', default_unit: 'Hz',   default_chart_type: 'line', default_color: '#6F42C1', position: 6 }
      ]
    },
    {
      name: 'Fluid',
      position: 6,
      measurement_subtypes_attributes: [
        { name: 'Pressure',            data_category: 'analog',  value_type: 'instantaneous', default_unit: 'Bar',  default_chart_type: 'line', default_color: '#DC3545', position: 1 },
        { name: 'Flow Rate',           data_category: 'analog',  value_type: 'instantaneous', default_unit: 'm³/h', default_chart_type: 'line', default_color: '#0D6EFD', position: 2 },
        { name: 'Volume',              data_category: 'counter', value_type: 'accumulative',  default_unit: 'L',    default_chart_type: 'bar',  default_color: '#39A0CA', position: 3 },
        { name: 'Volume Meter',        data_category: 'analog',  value_type: 'accumulative',  default_unit: 'L',    default_chart_type: 'bar',  default_color: '#39A0CA', position: 4 },
        { name: 'Level',               data_category: 'analog',  value_type: 'instantaneous', default_unit: '%',    default_chart_type: 'area', default_color: '#17A2B8', position: 5 },
        { name: 'Temperature',         data_category: 'analog',  value_type: 'instantaneous', default_unit: '°C',   default_chart_type: 'line', default_color: '#FF8C00', icon_key: 'temperature', position: 6 }
      ]
    },
    {
      name: 'Switch',
      position: 7,
      measurement_subtypes_attributes: [
        { name: 'Irrigation',          data_category: 'status', value_type: 'status', default_unit: 'Closed/Open',  default_chart_type: 'step', default_color: '#398439', icon_key: 'irrigation', position: 1 },
        { name: 'Fertigation',         data_category: 'status', value_type: 'status', default_unit: 'Closed/Open',  default_chart_type: 'step', default_color: '#6B8E23', icon_key: 'fertigation', position: 2 },
        { name: 'Valve',               data_category: 'status', value_type: 'status', default_unit: 'Closed/Open',  default_chart_type: 'step', default_color: '#398439', position: 3 },
        { name: 'Pump',                data_category: 'status', value_type: 'status', default_unit: 'Off/On',       default_chart_type: 'step', default_color: '#50C878', position: 4 },
        { name: 'Fan',                 data_category: 'status', value_type: 'status', default_unit: 'Off/On',       default_chart_type: 'step', default_color: '#5C6267', icon_key: 'fan', position: 5 },
        { name: 'Heater',              data_category: 'status', value_type: 'status', default_unit: 'Off/On',       default_chart_type: 'step', default_color: '#FF8C00', icon_key: 'heater', position: 6 },
        { name: 'Curtain',             data_category: 'status', value_type: 'status', default_unit: 'Closed/Open',  default_chart_type: 'step', default_color: '#8B4513', position: 7 },
        { name: 'Window',              data_category: 'status', value_type: 'status', default_unit: 'Closed/Open',  default_chart_type: 'step', default_color: '#39A0CA', position: 8 },
        { name: 'Light',               data_category: 'status', value_type: 'status', default_unit: 'Off/On',       default_chart_type: 'step', default_color: '#F0E68C', icon_key: 'light', position: 9 },
        { name: 'Humidifier',          data_category: 'status', value_type: 'status', default_unit: 'Off/On',       default_chart_type: 'step', default_color: '#39AFCA', icon_key: 'humidifier', position: 10 },
        { name: 'Door',                data_category: 'status', value_type: 'status', default_unit: 'Closed/Open',  default_chart_type: 'step', default_color: '#0D6EFD', position: 11 },
        { name: 'Compressor',          data_category: 'status', value_type: 'status', default_unit: 'Off/On',       default_chart_type: 'step', default_color: '#6C757D', position: 12 },
        { name: 'Motor',               data_category: 'status', value_type: 'status', default_unit: 'Off/On',       default_chart_type: 'step', default_color: '#495057', position: 13 },
        { name: 'Alarm',               data_category: 'status', value_type: 'status', default_unit: 'OK/Fault',     default_chart_type: 'step', default_color: '#DC3545', position: 14 }
      ]
    }
  ])

  def find_measurement_subtype!(measurement_type_name, name)
    measurement_subtype = MeasurementSubtype
      .joins(:measurement_type)
      .find_by(measurement_types: { name: measurement_type_name }, name: name)

    if measurement_subtype.nil?
      raise "MeasurementSubtype not found: #{measurement_type_name} > #{name}"
    end

    measurement_subtype
  end

  METRIC_DEFINITIONS = [
    {
      key: 'temperature',
      label: 'Temperature',
      unit: '°C',
      factor: 1.0,
      offset: 0.0,
      measurement_subtype: { measurement_type_name: 'Weather', name: 'Temperature' }
    },
    {
      key: 'humidity',
      label: 'Humidity',
      unit: '%',
      factor: 1.0,
      offset: 0.0,
      measurement_subtype: { measurement_type_name: 'Weather', name: 'Humidity' }
    },
    {
      key: 'precipitation',
      label: 'Precipitation',
      unit: 'mm',
      factor: 1.0,
      offset: 0.0,
      measurement_subtype: { measurement_type_name: 'Weather', name: 'Precipitation' }
    },
    {
      key: 'wind_speed',
      label: 'Wind Speed',
      unit: 'm/s',
      factor: 1.0,
      offset: 0.0,
      measurement_subtype: { measurement_type_name: 'Weather', name: 'Wind Speed' }
    },
    {
      key: 'wind_direction',
      label: 'Wind Direction',
      unit: '°',
      factor: 1.0,
      offset: 0.0,
      measurement_subtype: { measurement_type_name: 'Weather', name: 'Wind Direction' }
    },
    {
      key: 'barometric_pressure',
      label: 'Barometric Pressure',
      unit: 'mb',
      factor: 1.0,
      offset: 0.0,
      measurement_subtype: { measurement_type_name: 'Weather', name: 'Barometric Pressure' }
    },
    {
      key: 'global_radiation',
      label: 'Global Radiation',
      unit: 'W/m²',
      factor: 1.0,
      offset: 0.0,
      measurement_subtype: { measurement_type_name: 'Weather', name: 'Global Radiation' }
    },
    {
      key: 'direct_radiation',
      label: 'Direct Radiation',
      unit: 'W/m²',
      factor: 1.0,
      offset: 0.0,
      measurement_subtype: { measurement_type_name: 'Weather', name: 'Direct Radiation' }
    },
    {
      key: 'diffused_radiation',
      label: 'Diffused Radiation',
      unit: 'W/m²',
      factor: 1.0,
      offset: 0.0,
      measurement_subtype: { measurement_type_name: 'Weather', name: 'Diffused Radiation' }
    }
  ].freeze

  METRIC_DEFINITIONS.each do |defn|
    measurement_subtype = find_measurement_subtype!(defn[:measurement_subtype][:measurement_type_name], defn[:measurement_subtype][:name])
    WeatherStationApiMetric.create!(
      key: defn[:key],
      label: defn[:label],
      unit: defn[:unit],
      factor: defn[:factor],
      offset: defn[:offset],
      measurement_subtype: measurement_subtype
    )
  end

  semtech_manufacturer = Manufacturer.create!(
    name: 'Semtech',
    models_attributes: [{ name: 'LX40 EMEA', device_type: 'gateway' }]
  )
end
