# Usage:
#   rails runner db/seeds/modbus_registers_sg3202.rb

ActiveRecord::Base.transaction do
  manufacturer = Manufacturer.find_or_create_by!(name: 'Billion Watts')
  model = Model.find_or_create_by!(
    manufacturer: manufacturer,
    name:         'SG3202',
    device_type:  'modbus_device'
  )

  version = ModbusFirmwareVersion.create!(
    name: 'v1.0',
    version_code: '1.0',
    is_latest: true,
    is_supported: true,
    model: model
  )

  host_version = ModbusFirmwareVersion.first
  ModbusFirmwareCompatibility.create!(
    host_version:       host_version,
    peripheral_version: version,
    firmware_code:      2
  )

  registers = [
    { rel: 0, name: 'Power',   category: 'analog',  address: 16, data_type: 'uint32', value_format: 'numeric', unit: 'W',   factor: 1.0,   read_only: true, value_type: 'instantaneous', count: 2 },
    { rel: 2, name: 'Energy',  category: 'counter', address: 18, data_type: 'uint32', value_format: 'numeric', unit: 'Wh',  factor: 10,    read_only: true, value_type: 'accumulative',  count: 2 },
    { rel: 6, name: 'Voltage', category: 'analog',  address: 22, data_type: 'uint16', value_format: 'numeric', unit: 'V',   factor: 0.1,   read_only: true, value_type: 'instantaneous', count: 1 },
    { rel: 7, name: 'Current', category: 'analog',  address: 23, data_type: 'uint16', value_format: 'numeric', unit: 'A',   factor: 0.01,  read_only: true, value_type: 'instantaneous', count: 1 }
  ]

  registers.each_with_index do |r, i|
    label = r[:name].parameterize(separator: '_')

    default_subtype = MeasurementSubtype.find_by(
      data_category: r[:category],
      default_unit:  r[:unit]
    )

    template = RegisterTemplate.create!(
      name:            r[:name],
      label:           label,
      description:     "SG3202 #{r[:name]} (holding register #{r[:address]})",
      address:         r[:address],
      address_count:   r[:count],
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
      default_measurement_subtype: default_subtype,
      modbus_firmware_version: version
    )

    ModbusFirmwareRelayMapping.create!(
      modbus_firmware_version: host_version,
      register_template:       template,
      relay_offset:            r[:rel]
    )
  end
end
