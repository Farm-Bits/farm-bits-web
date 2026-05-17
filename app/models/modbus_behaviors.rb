# Resolver for Modbus device behavior profiles.
#
# Each ModbusFirmwareVersion has a `behavior_profile` string that maps to a
# behavior class. The class defines what the backend can do with
# that Modbus Firmware Version.
#
# Accepts any entity whose firmware version carries a `behavior_profile`:
# a Plc, or a ModbusDevice (gateway-direct or PLC-relayed).
#
# Usage:
#   behavior = ModbusBehaviors.for(plc_or_modbus_device)
#   behavior.sync_clock!          # runs or no-ops based on version
#   behavior.sync_io_active!      # same
#
module ModbusBehaviors
  REGISTRY = {
    'standard_v1' => 'ModbusBehaviors::StandardV1'
  }.freeze

  def self.for(device)
    profile = device.modbus_firmware_version&.behavior_profile
    if !profile.present?
      return ModbusBehaviors::Base.new(device)
    end

    class_name = REGISTRY[profile]

    if !class_name.present?
      Rails.logger.warn(
        "[ModbusBehaviors] Unknown profile '#{profile}' for ModbusFirmwareVersion #{device.modbus_firmware_version_id}"
      )
      return ModbusBehaviors::Base.new(device)
    end

    class_name.constantize.new(device)
  end

  def self.registered_profiles
    REGISTRY.keys
  end

  def self.class_for(profile)
    class_name = REGISTRY[profile]
    class_name&.constantize
  end
end
