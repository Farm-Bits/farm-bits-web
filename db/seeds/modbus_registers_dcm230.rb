# Usage:
#   rails runner db/seeds/modbus_registers_dcm230.rb

ActiveRecord::Base.transaction do
  manufacturer = Manufacturer.find_or_create_by!(name: 'Eastron')
  model = Model.find_or_create_by!(
    manufacturer: manufacturer,
    name: 'DCM230',
    device_type: 'modbus_device',
    display_type: 'Energy Meter',
    supports_modbus_tcp: false,
    supports_modbus_rtu: true
  )

  version = ModbusFirmwareVersion.create!(
    name: 'v1.5',
    version_code: '1.5',
    address_offset: 0,
    is_latest: true,
    is_supported: true,
    model: model
  )

  host_version = ModbusFirmwareVersion.first
  ModbusFirmwareCompatibility.create!(
    host_version:       host_version,
    peripheral_version: version,
    firmware_code:      1
  )

  registers = [
    { rel: 0, name: 'Voltage', category: 'analog',  address: 1,   data_type: 'float32', value_format: 'numeric', unit: 'V',   factor: 1.0, read_only: true, value_type: 'instantaneous' },
    { rel: 2, name: 'Current', category: 'analog',  address: 7,   data_type: 'float32', value_format: 'numeric', unit: 'A',   factor: 1.0, read_only: true, value_type: 'instantaneous' },
    { rel: 4, name: 'Power',   category: 'analog',  address: 13,  data_type: 'float32', value_format: 'numeric', unit: 'W',   factor: 1.0, read_only: true, value_type: 'instantaneous' },
    { rel: 6, name: 'Energy',  category: 'counter', address: 343, data_type: 'float32', value_format: 'numeric', unit: 'Wh',  factor: 1000.0, read_only: true, value_type: 'accumulative'  }
  ]

  registers.each_with_index do |r, i|
    label = r[:name].parameterize(separator: '_')

    default_subtype = MeasurementSubtype.find_by(
      data_category: r[:category],
      default_unit: r[:unit]
    )

    template = RegisterTemplate.create!(
      name:          r[:name],
      label:         label,
      description:   "DCM230 #{r[:name]} (input register #{r[:address]})",
      address:       r[:address],
      address_count: 2,
      register_type: 'input',
      data_type:     r[:data_type],
      byte_order:    'big_endian',
      value_format:  r[:value_format],
      factor:        r[:factor],
      offset:        0.0,
      category:      r[:category],
      read_only:     r[:read_only],
      user_visibility: 'visible',
      position:      i + 1,
      default_measurement_subtype: default_subtype,
      modbus_firmware_version: version
    )

    ModbusFirmwareRelayMapping.create!(
      modbus_firmware_version: host_version,
      register_template:       template,
      relay_offset:            r[:rel],
      direction:               'read'
    )
  end
end
