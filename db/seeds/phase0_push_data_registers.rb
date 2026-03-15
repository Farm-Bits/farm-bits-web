# Usage:
#   rails runner db/seeds/phase0_push_data_registers.rb
#

ActiveRecord::Base.transaction do

  SMTP_CONFIGURATION_REGISTERS = [
    {
      name: 'SMTP Hostname',
      label: 'SMTP_Hostname',
      description: 'SMTP server hostname for push data notifications',
      address_count: 16,
      register_type: 'holding',
      data_type: 'string',
      byte_order: 'big_endian',
      value_format: 'ascii_string',
      factor: 1.0,
      offset: 0.0,
      category: 'configuration',
      group_name: 'smtp_push_data',
      group_role: 'hostname',
      read_only: false,
      default_value: 'plc.farm-bits.com'
    },
    {
      name: 'SMTP Port',
      label: 'SMTP_Port',
      description: 'SMTP server port for push data notifications',
      address_count: 1,
      register_type: 'holding',
      data_type: 'uint16',
      byte_order: 'big_endian',
      value_format: 'numeric',
      factor: 1.0,
      offset: 0.0,
      category: 'configuration',
      group_name: 'smtp_push_data',
      group_role: 'port',
      read_only: false,
      default_value: 25
    },
    {
      name: 'SMTP Username',
      label: 'SMTP_Username',
      description: 'SMTP server username for push data notifications',
      address_count: 16,
      register_type: 'holding',
      data_type: 'string',
      byte_order: 'big_endian',
      value_format: 'ascii_string',
      factor: 1.0,
      offset: 0.0,
      category: 'configuration',
      group_name: 'smtp_push_data',
      group_role: 'username',
      read_only: false
    },
    {
      name: 'SMTP Password',
      label: 'SMTP_Password',
      description: 'SMTP server password for push data notifications',
      address_count: 16,
      register_type: 'holding',
      data_type: 'string',
      byte_order: 'big_endian',
      value_format: 'ascii_string',
      factor: 1.0,
      offset: 0.0,
      category: 'configuration',
      group_name: 'smtp_push_data',
      group_role: 'password',
      read_only: false
    },
    {
      name: 'SMTP To Email',
      label: 'SMTP_To_Email',
      description: 'Destination email address for push data notifications',
      address_count: 16,
      register_type: 'holding',
      data_type: 'string',
      byte_order: 'big_endian',
      value_format: 'ascii_string',
      factor: 1.0,
      offset: 0.0,
      category: 'configuration',
      group_name: 'smtp_push_data',
      group_role: 'to_email',
      read_only: false,
      default_value: 'data@plc.farm-bits.com'
    }
  ]
  OFFSET_ADDRESS = 16384

  plc_version_id = PlcVersion.first.id
  previous_registers_size = 0
  position = RegisterTemplate.where(plc_version_id: plc_version_id).maximum(:position).to_i + 1
  SMTP_CONFIGURATION_REGISTERS.each do |smtp_configuration_register|
    RegisterTemplate.create!(smtp_configuration_register.merge({
      address: OFFSET_ADDRESS + previous_registers_size,
      user_visibility: 'hidden',
      position: position,
      plc_version_id: plc_version_id
    }))

    previous_registers_size += smtp_configuration_register[:address_count]
    position += 1
  end
end
