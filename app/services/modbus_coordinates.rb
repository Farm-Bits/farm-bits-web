# Value object describing how to read a single MeasurementPoint's value over
# Modbus. The only thing downstream code (strategies, read service, VPN client)
# needs to know about topology.
#
#
# bulk_strategy selects the planner via ReadStrategy.resolve:
#   :bulk_read          - uses RegisterTemplate#bulk_read_group/address/offset
#   :individual         - one Modbus read per MP
#   anything else       - the host firmware's relay_read_strategy
#                         (e.g. :contiguous), routed through RelayReadStrategyRegistry
#
# All addresses are wire-ready (MODBUS_ADDRESS_OFFSET already applied).
#
ModbusCoordinates = Struct.new(
  :gateway,
  :target_ip,
  :slave_id,
  :register_type,
  :address,
  :count,
  :bulk_strategy,
  :template_bulk_group,    # :template_bulk_read only
  :template_bulk_base,     # :template_bulk_read only (wire-ready)
  :template_bulk_offset,   # :template_bulk_read only
  :relay_slot_number,      # relay strategies only
  :relay_modbus_device_id, # relay strategies only
  keyword_init: true
) do
  # Stable key. Two coordinates with the same key share a Modbus session.
  def endpoint_key
    [gateway.id, target_ip, slave_id]
  end
end
