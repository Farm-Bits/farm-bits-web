# Service to write values to PLC registers via the VPN Manager.
#
# Handles:
# - Single register writes
# - Bulk configuration writes (multiple registers in one Modbus connection)
# - Reverse factor/offset transformation (display value → raw register value)
# - Encoding values to Modbus register format
# - Updating last_decoded_value after successful writes
# - Logging every write to PlcWriteLog for full traceability
# - Touching PLC/gateway last_seen_at timestamps
#
# Usage:
#   # Single write (user action)
#   context = PlcWriteContext.user_action(current_user)
#   service = PlcWriteService.new(measurement_point)
#   result = service.write!(value, context: context)
#
#   # Bulk write (user action)
#   context = PlcWriteContext.user_action(current_user)
#   service = PlcWriteService.new(measurement_point)
#   result = service.bulk_write!(measurement_points_with_values, context: context)
#
#   # System action (background job)
#   context = PlcWriteContext.system_action('sun_data_sync')
#   service = PlcWriteService.new(measurement_point)
#   result = service.write!(value, context: context)
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
  # @param context [PlcWriteContext] traceability context (who, why, batch)
  # @return [Hash] { success: true, measurement_point: MeasurementPoint }
  # @raise [ValidationError] if value is out of bounds or register is read-only
  # @raise [ConnectionError] if PLC/gateway is unreachable
  # @raise [WriteError] if PLC rejects the write
  def write!(value, context: nil)
    context ||= PlcWriteContext.system_action('user')

    validate_gateway!

    raw_value = @measurement_point.reverse_scaled(value)

    validate_writable!(@measurement_point)
    validate_bounds!(@measurement_point, raw_value)

    begin
      client = VpnManagerClient.new
      client.write_register(@measurement_point, raw_value)
    rescue VpnManagerClient::ConnectionError => e
      raise ConnectionError, 'PLC is not reachable. Please check the gateway connection.'
    rescue VpnManagerClient::Error => e
      raise WriteError, "Failed to write to PLC: #{e.message}"
    end

    old_value = @measurement_point.last_decoded_value
    store_written_value(@measurement_point, raw_value)
    log_write(@measurement_point, old_value, raw_value, context)
    touch_devices!

    { success: true, measurement_point: @measurement_point }
  end

  # Write multiple configuration values in a single bulk Modbus operation.
  #
  # @param measurement_points_with_values [Array<Hash>] array of { measurement_point: MeasurementPoint, value: Object }
  # @param context [PlcWriteContext] traceability context (who, why, batch)
  # @return [Hash] { success: true, results: Hash<Integer, Hash> }
  # @raise [ValidationError] if any register is read-only
  # @raise [ConnectionError] if PLC/gateway is unreachable
  # @raise [WriteError] if any individual write fails
  def bulk_write!(measurement_points_with_values, context: nil)
    context ||= PlcWriteContext.system_action('user')

    validate_gateway!

    # Allow behavior profile to adjust MPs before encoding
    # (e.g., propagate source IO scaling to sensor condition thresholds)
    behavior = PlcBehaviors.for(@plc)
    measurement_points_with_values = behavior.pre_write_transforms(measurement_points_with_values)

    measurement_points_with_values.each do |entry|
      raw_value = entry[:measurement_point].reverse_scaled(entry[:value])

      validate_writable!(entry[:measurement_point])
      validate_bounds!(entry[:measurement_point], raw_value)

      entry[:value] = raw_value
    end

    # Capture old values before any writes
    old_values = {}
    measurement_points_with_values.each do |entry|
      old_values[entry[:measurement_point].id] = entry[:measurement_point].last_decoded_value
    end

    begin
      client = VpnManagerClient.new
      response = client.bulk_write_registers(@plc, measurement_points_with_values)
    rescue VpnManagerClient::ConnectionError => e
      raise ConnectionError, 'PLC is not reachable. Please check the gateway connection.'
    rescue VpnManagerClient::Error => e
      raise WriteError, "Failed to write configuration to PLC: #{e.message}"
    end

    if !response[:success]
      raise WriteError, response[:error] || 'Bulk write to PLC failed'
    end

    # Verify each result first (fail fast before any DB writes)
    measurement_points_with_values.each do |entry|
      measurement_point = entry[:measurement_point]
      result = response[:results][measurement_point.id]

      if result.nil? || result[:status] != 'ok'
        error_msg = result&.dig(:error) || 'No response from PLC'
        raise WriteError, "Failed to write '#{measurement_point.register_template.label}': #{error_msg}"
      end
    end

    # Bulk update last_decoded_value / _at for all measurement points
    bulk_store_written_values(measurement_points_with_values)

    # Bulk insert write logs
    bulk_log_writes(measurement_points_with_values, old_values, context)

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

    def validate_bounds!(measurement_point, raw_value)
      rt = measurement_point.register_template

      if !rt.numeric_register?
        return
      end

      if !rt.value_in_bounds?(raw_value.to_f)
        raise ValidationError, "Value out of range (#{rt.min_value}..#{rt.max_value})"
      end
    end

    def store_written_value(measurement_point, raw_value)
      serialized = measurement_point.serialize_for_storage(raw_value)

      measurement_point.update_columns(
        last_decoded_value: serialized,
        last_decoded_value_at: Time.current,
        updated_at: Time.current
      )
    end

    def log_write(measurement_point, old_value, new_value, context)
      begin
        serialized_new = measurement_point.serialize_for_storage(new_value)

        PlcWriteLog.create!(
          plc: @plc,
          site: measurement_point.site,
          user: context.user,
          measurement_point: measurement_point,
          register_template: measurement_point.register_template,
          source: context.source,
          old_value: old_value,
          new_value: serialized_new,
          batch_id: context.batch_id,
          created_at: Time.current
        )
      rescue => e
        # Log creation should never break the write operation
        Rails.logger.error(
          "Failed to create PlcWriteLog for MeasurementPoint #{measurement_point.id}: #{e.message}"
        )
      end
    end

    def bulk_store_written_values(entries)
      if entries.empty?
        return
      end

      now = Time.current
      mp_ids = entries.map { |e| e[:measurement_point].id }

      value_cases = entries.map do |entry|
        mp = entry[:measurement_point]
        serialized = mp.serialize_for_storage(entry[:value])
        "WHEN #{mp.id.to_i} THEN #{ActiveRecord::Base.connection.quote(serialized)}"
      end.join(' ')

      MeasurementPoint.where(id: mp_ids).update_all(
        "last_decoded_value = CASE id #{value_cases} END, " \
        "last_decoded_value_at = #{ActiveRecord::Base.connection.quote(now)}, " \
        "updated_at = #{ActiveRecord::Base.connection.quote(now)}"
      )
    end

    def bulk_log_writes(entries, old_values, context)
      if entries.empty?
        return
      end

      now = Time.current
      rows = entries.map do |entry|
        mp = entry[:measurement_point]
        {
          plc_id: @plc.id,
          site_id: mp.site_id,
          user_id: context.user&.id,
          measurement_point_id: mp.id,
          register_template_id: mp.register_template_id,
          source: context.source,
          old_value: old_values[mp.id],
          new_value: mp.serialize_for_storage(entry[:value]),
          batch_id: context.batch_id,
          created_at: now
        }
      end

      begin
        PlcWriteLog.insert_all(rows)
      rescue => e
        Rails.logger.error("Failed to bulk insert PlcWriteLogs: #{e.message}")
      end
    end

    def touch_devices!
      @plc.update_columns(last_seen_at: Time.current)
      @gateway.update_columns(last_seen_at: Time.current)
    end
end
