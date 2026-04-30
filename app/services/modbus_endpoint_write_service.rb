# Per-endpoint wire executor for writes. Mirrors ModbusEndpointReadService.
#
# Concerns:
#   - Encode each entry's raw value via register_template#encode_value
#   - Issue a single bulk_write to the VPN manager for this endpoint
#   - Return the response unmodified for the orchestrator to validate
#
# NOT this service's concerns:
#   - Validation, scaling, behavior transforms, persistence, logging
#     (all of those live in ModbusWriteService)
#
# Errors raised here propagate as VpnManagerClient errors; ModbusWriteService
# translates them to its own error hierarchy.
#
class ModbusEndpointWriteService
  def initialize(gateway:, target_ip:, slave_id:, entries:)
    @gateway   = gateway
    @target_ip = target_ip
    @slave_id  = slave_id
    @entries   = entries
  end

  # @return [Hash] { success:, error:, error_type:, results: }
  #   results: { mp_id => { status:, values:, error: } }
  def call
    if @entries.empty?
      return { success: true, error: nil, error_type: nil, results: {} }
    end

    writes = @entries.map do |entry|
      mp     = entry[:measurement_point]
      coords = entry[:write_coordinates]

      {
        id:            mp.id,
        register_type: coords.register_type,
        address:       coords.address,
        values:        mp.register_template.encode_value(entry[:raw_value])
      }
    end

    VpnManagerClient.new.bulk_write_registers(
      gateway_label: @gateway.label,
      target_ip:     @target_ip,
      slave_id:      @slave_id,
      writes:        writes
    )
  end
end
