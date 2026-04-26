# Usage:
#   rails runner db/seeds/modbus_registers_dcm230.rb

ActiveRecord::Base.transaction do

  manufacturer = Manufacturer.find_or_create_by!(name: 'Eastron')
  model = Model.find_or_create_by!(
    manufacturer: manufacturer,
    name: 'DCM230',
    device_type: 'modbus_device'
  )

  version = ModbusFirmwareVersion.find_or_create_by!(name: 'v1.5', model: model) do |v|
    v.version_code = '1.5'
    v.is_latest    = true
    v.is_supported = true
  end

  registers = [
    { rel: 0, name: 'Voltage', category: 'analog',  address: 0,   data_type: 'float32', value_format: 'numeric', unit: 'V',   read_only: true, value_type: 'instantaneous' },
    { rel: 2, name: 'Current', category: 'analog',  address: 6,   data_type: 'float32', value_format: 'numeric', unit: 'A',   read_only: true, value_type: 'instantaneous' },
    { rel: 4, name: 'Power',   category: 'analog',  address: 12,  data_type: 'float32', value_format: 'numeric', unit: 'W',   read_only: true, value_type: 'instantaneous' },
    { rel: 6, name: 'Energy',  category: 'counter', address: 342, data_type: 'float32', value_format: 'numeric', unit: 'kWh', read_only: true, value_type: 'accumulative'  }
  ]

  registers.each_with_index do |r, i|
    label = r[:name].parameterize(separator: '_')

    default_subtype = MeasurementSubtype.find_by(
      data_category: r[:category],
      default_unit: r[:unit]
    )

    RegisterTemplate.create!(
      name:          r[:name],
      label:         label,
      description:   "DCM230 #{r[:name]} (input register #{r[:address]})",
      address:       r[:address],
      address_count: 2,
      relay_offset:  r[:rel],
      register_type: 'input',
      data_type:     r[:data_type],
      byte_order:    'big_endian',
      value_format:  r[:value_format],
      factor:        1.0,
      offset:        0.0,
      category:      r[:category],
      read_only:     r[:read_only],
      user_visibility: 'visible',
      position:      i + 1,
      default_measurement_subtype: default_subtype,
      modbus_firmware_version: version
    )
  end

  host_version = ModbusFirmwareVersion.first
  ModbusDeviceCompatibility.find_or_create_by!(
    host_version: host_version,
    peripheral_version: version,
    firmware_code: 1
  )

end
