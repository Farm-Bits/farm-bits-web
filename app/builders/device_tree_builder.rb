# Builds the nested tree of devices for the Devices index page from a
# pre-scoped collection of Gateways, Plcs, and ModbusDevices (assumed
# already filtered to the current site by the caller via policy_scope).
#
# Output: an Array of "row" Hashes representing the top level of the tree.
# Each row carries display info plus its children Array.
#
# Row shape:
#   {
#     row_key:       "gateway-42",        # unique across kinds for v-for :key
#     kind:          'gateway' | 'plc' | 'modbus_device',
#     id:            <db id>,
#     name:          <user-set display name>,
#     display_type:  <human label for the Type column>,
#     status:        'online' | 'offline' | 'awaiting_setup' | 'disabled',
#     last_seen_at:  <ISO8601 string or nil>,
#     active:        <bool>,
#     details:       { ... entity-specific fields needed by edit modals },
#     children:      [<more rows>]
#   }
#
# Tree topology:
#   Level 0: Gateways (active and inactive); orphan PLCs (gateway_id nil);
#            orphan ModbusDevices (both gateway_id and plc_id nil)
#   Level 1: PLCs assigned to a Gateway; ModbusDevices polled directly by a Gateway
#   Level 2: ModbusDevices bridged through a PLC (PLC-hosted)
#
# Within a level, ordering is: active first, then inactive (awaiting_setup),
# alphabetical within each group.
#
# Status logic differs per kind:
#   - Gateway / PLC: active=false → 'awaiting_setup' (admin-provisioned but
#     not yet activated by user). Active → online/offline by last_seen_at.
#   - ModbusDevice: active=false → 'disabled' (user toggled polling off).
#     Active → online/offline by last_seen_at.
#
# WHERE TO PUT THIS: app/services/device_tree_builder.rb

class DeviceTreeBuilder
  ONLINE_THRESHOLD = 5.minutes

  # Minimum eager loading required for this builder to avoid N+1.
  GATEWAY_INCLUDES        = [:model].freeze
  PLC_INCLUDES            = [:model, :modbus_firmware_version].freeze
  MODBUS_DEVICE_INCLUDES  = [:model, :modbus_firmware_version].freeze

  def initialize(gateways:, plcs:, modbus_devices:)
    @gateways       = gateways.to_a
    @plcs           = plcs.to_a
    @modbus_devices = modbus_devices.to_a
  end

  def build
    # Index children by parent id for O(1) lookup
    plcs_by_gateway_id           = @plcs.group_by(&:gateway_id)
    modbus_by_plc_id             = @modbus_devices.group_by(&:plc_id)
    modbus_by_gateway_id         = @modbus_devices.group_by(&:gateway_id)

    rows = []

    # Top-level: gateways
    sorted_gateways = sort_entities(@gateways)
    sorted_gateways.each do |gw|
      gw_children = []

      # PLCs assigned to this gateway
      plcs_under = sort_entities(plcs_by_gateway_id[gw.id] || [])
      plcs_under.each do |plc|
        plc_children = (modbus_by_plc_id[plc.id] || [])
          .reject { |md| md.gateway_id.present? }  # paranoid: shouldn't happen given mutex validation
        plc_children = sort_entities(plc_children)
        gw_children << build_plc_row(plc, plc_children.map { |md| build_modbus_device_row(md) })
      end

      # Modbus devices polled directly by this gateway
      direct_modbus = sort_entities(modbus_by_gateway_id[gw.id] || [])
      direct_modbus.each do |md|
        gw_children << build_modbus_device_row(md)
      end

      rows << build_gateway_row(gw, gw_children)
    end

    # Top-level: orphan PLCs (gateway_id nil) — typically inactive, awaiting setup
    orphan_plcs = sort_entities(plcs_by_gateway_id[nil] || [])
    orphan_plcs.each do |plc|
      plc_children = (modbus_by_plc_id[plc.id] || []).reject { |md| md.gateway_id.present? }
      plc_children = sort_entities(plc_children).map { |md| build_modbus_device_row(md) }
      rows << build_plc_row(plc, plc_children)
    end

    # Top-level: orphan modbus devices (both parents nil — shouldn't normally exist
    # but render defensively rather than swallow them silently)
    orphan_modbus = @modbus_devices.select { |md| md.gateway_id.nil? && md.plc_id.nil? }
    sort_entities(orphan_modbus).each do |md|
      rows << build_modbus_device_row(md)
    end

    rows
  end

  private
    # ── Row builders ─────────────────────────────────────────────

    def build_gateway_row(gw, children)
      {
        row_key:      "gateway-#{gw.id}",
        kind:         'gateway',
        id:           gw.id,
        name:         gw.name,
        display_type: gw.model&.display_type.presence || 'Gateway',
        status:       status_for_provisioned(gw),
        last_seen_at: gw.last_seen_at&.iso8601,
        active:       gw.active?,
        details:      gateway_details(gw),
        children:     children
      }
    end

    def build_plc_row(plc, children)
      {
        row_key:      "plc-#{plc.id}",
        kind:         'plc',
        id:           plc.id,
        name:         plc.name,
        display_type: plc.model&.display_type.presence || 'Controller',
        status:       status_for_provisioned(plc),
        last_seen_at: plc.last_seen_at&.iso8601,
        active:       plc.active?,
        details:      plc_details(plc),
        children:     children
      }
    end

    def build_modbus_device_row(md)
      {
        row_key:      "modbus_device-#{md.id}",
        kind:         'modbus_device',
        id:           md.id,
        name:         md.name,
        display_type: md.model&.display_type.presence || 'Device',
        status:       status_for_user_managed(md),
        last_seen_at: md.last_seen_at&.iso8601,
        active:       md.active?,
        details:      modbus_device_details(md),
        children:     []
      }
    end

    # ── Status logic ─────────────────────────────────────────────
    #
    # Gateway & PLC: active=false means "admin-provisioned, awaiting user setup"
    # ModbusDevice:  active=false means "polling disabled by user" (created and
    #                hosted, but explicitly turned off)

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

    # ── Sorting ──────────────────────────────────────────────────
    # Active first, then inactive; alphabetical within each group.

    def sort_entities(entities)
      entities.sort_by { |e| [e.active? ? 0 : 1, (e.name || '').downcase] }
    end

    # ── Detail blocks (consumed by edit/setup modals) ────────────

    def gateway_details(gw)
      {
        label:          gw.label,
        imei:           gw.imei,
        iccid:          gw.iccid,
        phone_number:   gw.phone_number,
        private_ip:     gw.private_ip,
        serial_number:  gw.serial_number,
        model:          model_summary(gw.model)
      }
    end

    def plc_details(plc)
      {
        label:                   plc.label,
        slave_id:                plc.slave_id,
        private_ip:              plc.private_ip,
        serial_number:           plc.serial_number,
        gateway_id:              plc.gateway_id,
        model:                   model_summary(plc.model),
        modbus_firmware_version: firmware_summary(plc.modbus_firmware_version)
      }
    end

    def modbus_device_details(md)
      {
        label:                   md.label,
        slave_id:                md.slave_id,
        private_ip:              md.private_ip,
        slot_number:             md.slot_number,
        gateway_id:              md.gateway_id,
        plc_id:                  md.plc_id,
        host_kind:               md.gateway_id.present? ? 'gateway' : (md.plc_id.present? ? 'plc' : nil),
        model:                   model_summary(md.model),
        modbus_firmware_version: firmware_summary(md.modbus_firmware_version)
      }
    end

    def model_summary(model)
      if model.nil?
        return nil
      end

      {
        id:           model.id,
        name:         model.name,
        full_name:    model.full_name,
        display_type: model.display_type,
        device_type:  model.device_type
      }
    end

    def firmware_summary(version)
      if version.nil?
        return nil
      end

      {
        id:           version.id,
        name:         version.name,
        version_code: version.version_code
      }
    end
end
