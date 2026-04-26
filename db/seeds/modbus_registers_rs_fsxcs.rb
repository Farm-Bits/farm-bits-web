# Usage:
#   rails runner db/seeds/modbus_registers_rs_fsxcs.rb

ActiveRecord::Base.transaction do
  manufacturer = Manufacturer.find_or_create_by!(name: 'Renke')
  model = Model.find_or_create_by!(
    manufacturer: manufacturer,
    name:         'RS-FSXCS',
    device_type:  'modbus_device'
  )

  version = ModbusFirmwareVersion.find_or_create_by!(name: 'v1.2', model: model) do |v|
    v.version_code = '1.2'
    v.is_latest    = true
    v.is_supported = true
  end

  # Compass octant enum for register 502. Maps 0..7 to N/NE/E/.../NW.
  wind_direction_octants = {
    '0' => 'North',
    '1' => 'Northeast',
    '2' => 'East',
    '3' => 'Southeast',
    '4' => 'South',
    '5' => 'Southwest',
    '6' => 'West',
    '7' => 'Northwest'
  }

  registers = [
    { rel: 0,  name: 'Wind Speed',            category: 'analog',  address: 500, data_type: 'uint16', value_format: 'numeric', unit: 'm/s',   factor: 0.01, read_only: true, value_type: 'instantaneous', count: 1 },
    { rel: 1,  name: 'Wind Force',            category: 'analog',  address: 501, data_type: 'uint16', value_format: 'numeric', unit: nil,     factor: 1.0,  read_only: true, value_type: 'instantaneous', count: 1 },
    { rel: 2,  name: 'Wind Direction (8-way)',category: 'status',  address: 502, data_type: 'uint16', value_format: 'enum',    unit: nil,     factor: 1.0,  read_only: true, value_type: 'status',        count: 1, enum_values: wind_direction_octants },
    { rel: 3,  name: 'Wind Direction',        category: 'analog',  address: 503, data_type: 'uint16', value_format: 'numeric', unit: '°',     factor: 1.0,  read_only: true, value_type: 'instantaneous', count: 1 },
    { rel: 4,  name: 'Humidity',              category: 'analog',  address: 504, data_type: 'uint16', value_format: 'numeric', unit: '%RH',   factor: 0.1,  read_only: true, value_type: 'instantaneous', count: 1 },
    { rel: 5,  name: 'Temperature',           category: 'analog',  address: 505, data_type: 'int16',  value_format: 'numeric', unit: '°C',    factor: 0.1,  read_only: true, value_type: 'instantaneous', count: 1 },
    { rel: 6,  name: 'Noise',                 category: 'analog',  address: 506, data_type: 'uint16', value_format: 'numeric', unit: 'dB',    factor: 0.1,  read_only: true, value_type: 'instantaneous', count: 1 },
    { rel: 7,  name: 'PM2.5',                 category: 'analog',  address: 507, data_type: 'uint16', value_format: 'numeric', unit: 'µg/m³', factor: 1.0,  read_only: true, value_type: 'instantaneous', count: 1 },
    { rel: 8,  name: 'PM10',                  category: 'analog',  address: 508, data_type: 'uint16', value_format: 'numeric', unit: 'µg/m³', factor: 1.0,  read_only: true, value_type: 'instantaneous', count: 1 },
    { rel: 9,  name: 'Atmospheric Pressure',  category: 'analog',  address: 509, data_type: 'uint16', value_format: 'numeric', unit: 'kPa',   factor: 0.1,  read_only: true, value_type: 'instantaneous', count: 1 },
    { rel: 10, name: 'Light',                 category: 'analog',  address: 510, data_type: 'uint32', value_format: 'numeric', unit: 'Lux',   factor: 1.0,  read_only: true, value_type: 'instantaneous', count: 2 },
    { rel: 13, name: 'Rainfall',              category: 'counter', address: 513, data_type: 'uint16', value_format: 'numeric', unit: 'mm',    factor: 0.1,  read_only: true, value_type: 'accumulative',  count: 1 }
  ]

  registers.each_with_index do |r, i|
    label = r[:name].parameterize(separator: '_')

    default_subtype = MeasurementSubtype.find_by(
      data_category: r[:category],
      default_unit:  r[:unit]
    )

    RegisterTemplate.create!(
      name:            r[:name],
      label:           label,
      description:     "RS-FSXCS #{r[:name]} (holding register #{r[:address]})",
      address:         r[:address],
      address_count:   r[:count],
      relay_offset:    r[:rel],
      register_type:   'holding',
      data_type:       r[:data_type],
      byte_order:      'big_endian',
      value_format:    r[:value_format],
      factor:          r[:factor],
      offset:          0.0,
      category:        r[:category],
      read_only:       r[:read_only],
      user_visibility: 'visible',
      position:        i + 1,
      enum_values:     r[:enum_values],
      default_measurement_subtype: default_subtype,
      modbus_firmware_version: version
    )
  end

  host_version = ModbusFirmwareVersion.first
  ModbusDeviceCompatibility.find_or_create_by!(
    host_version:       host_version,
    peripheral_version: version,
    firmware_code: 3
  )
end
