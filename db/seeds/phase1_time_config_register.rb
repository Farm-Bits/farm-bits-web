# Creates the utc_offset_minutes register template for each PlcVersion
# that has system_clock registers. This register belongs to the PLC
# globally (not interface-mapped), category: 'configuration'.
#
# Usage:
#   rails runner db/seeds/phase1_time_config_register.rb
#

ActiveRecord::Base.transaction do
  UTC_OFFSET_ADDRESS = 16449

  plc_version_id = PlcVersion.first.id
  position = RegisterTemplate.where(plc_version_id: plc_version_id).maximum(:position).to_i + 1
  register = RegisterTemplate.create!(
    name: 'UTC Offset Minutes',
    label: 'UtcOffsetMinutes',
    description: 'Current UTC offset for site timezone in minutes',
    address: UTC_OFFSET_ADDRESS,
    address_count: 1,
    register_type: 'holding',
    data_type: 'int16',
    byte_order: 'big_endian',
    value_format: 'numeric',
    factor: 1.0,
    offset: 0.0,
    category: 'configuration',
    group_name: 'time_config',
    group_role: 'utc_offset',
    read_only: false,
    user_visibility: 'hidden',
    min_value: -720,
    max_value: 840,
    default_value: 0,
    position: position,
    plc_version_id: plc_version_id
  )
end
