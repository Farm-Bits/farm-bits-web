# Service to write values to PLC registers via the VPN Manager.
#
# Handles:
# - Single register writes
# - Bulk configuration writes (multiple registers in one Modbus connection)
# - Reverse factor/offset transformation (display value → raw register value)
# - Encoding values to Modbus register format
# - Updating last_decoded_value after successful writes
# - Touching PLC/gateway last_seen_at timestamps
#
# Usage:
#   # Single write
#   service = PlcWriteService.new(measurement_point)
#   result = service.write!(value)
#
#   # Bulk write
#   service = PlcWriteService.new(measurement_point)
#   result = service.bulk_write!(config_points_with_values)
#
class PlcWriteService
  class WriteError < StandardError; end
  class ConnectionError < WriteError; end
  class ValidationError < WriteError; end

  # @param measurement_point [MeasurementPoint] the primary measurement point (used to resolve PLC/gateway)
  def initialize(measurement_point)
    @measurement_point = measurement_point
    @plc = measurement_point.plc
    @gateway = @plc.gateway
  end

  # Write a single value to a measurement point's register.
  #
  # @param value [String, Numeric, Boolean] the display/user-facing value
  # @return [Hash] { success: true, measurement_point: MeasurementPoint }
  # @raise [ValidationError] if value is out of bounds or register is read-only
  # @raise [ConnectionError] if PLC/gateway is unreachable
  # @raise [WriteError] if PLC rejects the write
  def write!(value)
    validate_gateway!
    validate_writable!(@measurement_point)
    validate_bounds!(@measurement_point, value)

    raw_value = @measurement_point.reverse_scaled(value)

    begin
      client = VpnManagerClient.new
      client.write_register(@measurement_point, raw_value)
    rescue VpnManagerClient::ConnectionError => e
      raise ConnectionError, 'PLC is not reachable. Please check the gateway connection.'
    rescue VpnManagerClient::Error => e
      raise WriteError, "Failed to write to PLC: #{e.message}"
    end

    store_written_value(@measurement_point, value)
    touch_devices!

    { success: true, measurement_point: @measurement_point }
  end

  # Write multiple configuration values in a single bulk Modbus operation.
  #
  # @param measurement_points_with_values [Array<Hash>] array of { measurement_point: MeasurementPoint, value: Object }
  # @return [Hash] { success: true, results: Hash<Integer, Hash> }
  # @raise [ValidationError] if any register is read-only
  # @raise [ConnectionError] if PLC/gateway is unreachable
  # @raise [WriteError] if any individual write fails
  def bulk_write!(measurement_points_with_values)
    validate_gateway!

    measurement_points_with_values.each do |entry|
      validate_writable!(entry[:measurement_point])
    end

    writes = measurement_points_with_values.map do |entry|
      measurement_point = entry[:measurement_point]
      register_template = measurement_point.register_template
      raw_value = measurement_point.reverse_scaled(entry[:value])

      {
        id: measurement_point.id,
        register_type: register_template.register_type,
        address: register_template.address,
        values: register_template.encode_value(raw_value)
      }
    end

    begin
      client = VpnManagerClient.new
      response = client.bulk_write_registers(@plc, writes)
    rescue VpnManagerClient::ConnectionError => e
      raise ConnectionError, 'PLC is not reachable. Please check the gateway connection.'
    rescue VpnManagerClient::Error => e
      raise WriteError, "Failed to write configuration to PLC: #{e.message}"
    end

    if !response[:success]
      raise WriteError, response[:error] || 'Bulk write to PLC failed'
    end

    # Verify each result and store written values
    measurement_points_with_values.each do |entry|
      measurement_point = entry[:measurement_point]
      result = response[:results][measurement_point.id]

      if result.nil? || result[:status] != 'ok'
        error_msg = result&.dig(:error) || 'No response from PLC'
        raise WriteError, "Failed to write '#{measurement_point.register_template.label}': #{error_msg}"
      end

      store_written_value(measurement_point, entry[:value])
    end

    touch_devices!

    { success: true, results: response[:results] }
  end

  private
    def validate_gateway!
      if !@gateway.present?
        raise ValidationError, 'No gateway assigned to this PLC'
      end
    end

    def validate_writable!(measurement_point)
      if measurement_point.register_template.read_only?
        raise ValidationError, "Register '#{measurement_point.register_template.label}' is read-only"
      end
    end

    def validate_bounds!(measurement_point, value)
      rt = measurement_point.register_template

      if !rt.numeric_register?
        return
      end

      raw_value = measurement_point.reverse_scaled(value)

      if !rt.value_in_bounds?(raw_value.to_f)
        raise ValidationError, "Value out of range (#{rt.min_value}..#{rt.max_value})"
      end
    end

    def store_written_value(measurement_point, value)
      serialized = measurement_point.serialize_for_storage(value)

      measurement_point.update_columns(
        last_decoded_value: serialized,
        last_decoded_value_at: Time.current,
        updated_at: Time.current
      )
    end

    def touch_devices!
      @plc.update_columns(last_seen_at: Time.current)
      @gateway.update_columns(last_seen_at: Time.current)
    end
end
