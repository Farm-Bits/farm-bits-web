# Builds the flat list of devices with programs for the Programs index page.
# Mirrors the row vocabulary from DeviceTreeBuilder so the frontend can
# share status badge / row chrome components.
#
# Returns a sorted array of:
#   {
#     row_key:      'plc-42' | 'modbus_device-7',
#     kind:         'plc' | 'modbus_device',
#     id:           Integer,
#     name:         String,
#     display_type: String,         # human label (model display_type)
#     firmware:     String,         # firmware version name
#     host:         String | nil,   # for relayed devices, the host PLC name
#     status:       'online' | 'offline' | 'awaiting_setup' | 'disabled',
#     last_seen_at: ISO8601 String | nil,
#     active:       Boolean
#   }
#
class ProgramsTreeBuilder
  ONLINE_THRESHOLD = 5.minutes

  def initialize(plcs:, modbus_devices:)
    @plcs           = plcs.to_a
    @modbus_devices = modbus_devices.to_a
  end

  def build
    rows = []

    @plcs.each do |plc|
      rows << {
        row_key:      "plc-#{plc.id}",
        kind:         'plc',
        id:           plc.id,
        name:         plc.name,
        display_type: plc.model&.display_type.presence || 'Controller',
        firmware:     plc.modbus_firmware_version&.name,
        host:         nil,
        status:       status_for_provisioned(plc),
        last_seen_at: plc.last_seen_at&.iso8601,
        active:       plc.active?
      }
    end

    @modbus_devices.each do |md|
      rows << {
        row_key:      "modbus_device-#{md.id}",
        kind:         'modbus_device',
        id:           md.id,
        name:         md.name,
        display_type: md.model&.display_type.presence || 'Device',
        firmware:     md.modbus_firmware_version&.name,
        host:         md.plc&.name,
        status:       status_for_user_managed(md),
        last_seen_at: md.last_seen_at&.iso8601,
        active:       md.active?
      }
    end

    rows.sort_by { |r| [r[:active] ? 0 : 1, (r[:name] || '').downcase] }
  end

  private
    def status_for_provisioned(entity)
      if !entity.active?
        return 'awaiting_setup'
      end

      status_from_last_seen(entity.last_seen_at)
    end

    def status_for_user_managed(entity)
      if !entity.active?
        return 'disabled'
      end

      status_from_last_seen(entity.last_seen_at)
    end

    def status_from_last_seen(timestamp)
      if timestamp.nil?
        return 'offline'
      end

      if timestamp > ONLINE_THRESHOLD.ago
        return 'online'
      end

      'offline'
    end
end
