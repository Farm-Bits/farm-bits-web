class UserArea::DevicesController < UserArea::ApplicationController
  def index
    authorize :device, :index?

    tree = DeviceTreeBuilder.new(
      gateways:       gateways_for_tree,
      plcs:           plcs_for_tree,
      modbus_devices: modbus_devices_for_tree
    ).build

    data = {
      tree: tree,
      add_device_options: add_device_options
    }

    respond_to do |format|
      format.html { render inertia: 'UserArea/Devices/index', props: data }
      format.json { render json: data, status: :ok }
    end
  end

  private
    def gateways_for_tree
      policy_scope(Gateway).includes(*DeviceTreeBuilder::GATEWAY_INCLUDES)
    end

    def plcs_for_tree
      policy_scope(Plc).includes(*DeviceTreeBuilder::PLC_INCLUDES)
    end

    def modbus_devices_for_tree
      policy_scope(ModbusDevice).includes(*DeviceTreeBuilder::MODBUS_DEVICE_INCLUDES)
    end

    def add_device_options
      {
        models:        modbus_device_models,
        hosts:         eligible_hosts,
        compatibility: compatibility_map
      }
    end

    def modbus_device_models
      Model
        .where(device_type: 'modbus_device')
        .includes(:manufacturer, :modbus_firmware_versions)
        .map do |model|
          {
            id:                  model.id,
            name:                model.name,
            full_name:           model.full_name,
            display_type:        model.display_type,
            supports_modbus_tcp: model.supports_modbus_tcp,
            supports_modbus_rtu: model.supports_modbus_rtu,
            firmware_versions:   model.modbus_firmware_versions.map do |v|
              {
                id:           v.id,
                name:         v.name,
                version_code: v.version_code,
                is_latest:    v.is_latest
              }
            end
          }
        end
    end

    def eligible_hosts
      gateways = policy_scope(Gateway)
        .where(active: true)
        .includes(:model)
        .map do |g|
          {
            kind:                'gateway',
            id:                  g.id,
            name:                g.name,
            label:               "Gateway: #{g.name}",
            supports_modbus_tcp: g.model&.supports_modbus_tcp || false,
            supports_modbus_rtu: g.model&.supports_modbus_rtu || false
          }
        end

      plcs = policy_scope(Plc)
        .joins(:modbus_firmware_version)
        .where(active: true)
        .where.not(modbus_firmware_versions: { relay_slot_base: nil })
        .includes(:model)
        .map do |p|
          {
            kind:                'plc',
            id:                  p.id,
            name:                p.name,
            label:               "Controller: #{p.name}",
            firmware_version_id: p.modbus_firmware_version_id,
            supports_modbus_tcp: p.model&.supports_modbus_tcp || false,
            supports_modbus_rtu: p.model&.supports_modbus_rtu || false
          }
        end

      { gateways: gateways, plcs: plcs }
    end

    def compatibility_map
      ModbusFirmwareCompatibility
        .all
        .group_by(&:host_version_id)
        .transform_values { |rows| rows.map(&:peripheral_version_id) }
    end
end
