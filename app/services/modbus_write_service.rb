class ModbusWriteService
  class WriteError      < StandardError; end
  class ConnectionError < WriteError; end
  class ValidationError < WriteError; end

  # Single-write convenience.
  def self.write!(measurement_point, value, context: nil)
    new.bulk_write!(
      [{ measurement_point: measurement_point, value: value }],
      context: context
    )
  end

  # @param entries [Array<Hash>] [{ measurement_point:, value: }, ...]
  # @param context [ModbusWriteContext, nil]
  # @return [Hash] { success: true, results: { mp_id => result_hash } }
  def bulk_write!(entries, context: nil)
    context ||= ModbusWriteContext.system_action('user')
    if entries.empty?
      return { success: true, results: {} }
    end

    entries  = apply_behavior_transforms(entries)
    prepared = prepare_entries(entries)

    old_values = capture_old_values(prepared)

    merged_results = dispatch_by_endpoint(prepared)

    verify_all_succeeded!(prepared, merged_results)

    bulk_store_written_values(prepared)
    bulk_log_writes(prepared, old_values, context)
    touch_endpoints!(prepared)

    { success: true, results: merged_results }
  end

  private
    # Behavior transforms are PLC-firmware-scoped; we apply them per host
    # PLC (which is either the MP's plc directly, or its modbus_device's
    # plc for relay writes). Gateway-direct ModbusDevice writes have no
    # host PLC and pass through unchanged.
    def apply_behavior_transforms(entries)
      grouped = entries.group_by do |e|
        behavior_host_plc_for(e[:measurement_point])&.id
      end

      grouped.flat_map do |host_plc_id, group|
        if host_plc_id.nil?
          next group
        end

        host = behavior_host_plc_for(group.first[:measurement_point])
        PlcBehaviors.for(host).pre_write_transforms(group)
      end
    end

    # Validate, scale, and resolve coordinates for every entry up front.
    # Any problem here raises before any wire activity, keeping
    # bulk_write! all-or-nothing.
    def prepare_entries(entries)
      entries.map do |entry|
        mp = entry[:measurement_point]

        validate_writable!(mp)

        raw_value = mp.reverse_scaled(entry[:value])
        validate_bounds!(mp, raw_value)

        coords = mp.write_coordinates
        if coords.nil?
          raise ValidationError,
            "MeasurementPoint #{mp.id} (#{mp.name}) has no write coordinates - " \
            "check that the register is writable and (if relayed) has a " \
            "write_to_peripheral relay mapping"
        end

        {
          measurement_point: mp,
          raw_value:         raw_value,
          write_coordinates: coords
        }
      end
    end

    def capture_old_values(prepared)
      prepared.each_with_object({}) do |entry, hash|
        hash[entry[:measurement_point].id] = entry[:measurement_point].last_decoded_value
      end
    end

    # Group by Modbus endpoint, fire one VPN request per endpoint. If any
    # endpoint fails with a connection error, abort the whole batch
    # before any persistence.
    def dispatch_by_endpoint(prepared)
      by_endpoint = prepared.group_by { |e| e[:write_coordinates].endpoint_key }
      merged_results = {}

      by_endpoint.each_value do |group|
        coords = group.first[:write_coordinates]

        response = nil
        begin
          response = ModbusEndpointWriteService.new(
            gateway:   coords.gateway,
            target_ip: coords.target_ip,
            slave_id:  coords.slave_id,
            entries:   group
          ).call
        rescue VpnManagerClient::ConnectionError => e
          raise ConnectionError, "PLC unreachable: #{e.message}"
        rescue VpnManagerClient::Error => e
          raise WriteError, "Failed to write to PLC: #{e.message}"
        end

        if !response[:success] && response[:error_type] == 'connection'
          raise ConnectionError, response[:error] || 'PLC unreachable'
        end

        if !response[:success]
          raise WriteError, response[:error] || 'Bulk write to PLC failed'
        end

        merged_results.merge!(response[:results] || {})
      end

      merged_results
    end

    def verify_all_succeeded!(prepared, merged_results)
      prepared.each do |entry|
        mp     = entry[:measurement_point]
        result = merged_results[mp.id]

        if result.nil? || result[:status] != 'ok'
          error_msg = result&.dig(:error) || 'No response from PLC'
          raise WriteError,
            "Failed to write '#{mp.register_template.label}': #{error_msg}"
        end
      end
    end

    # Bulk-update last_decoded_value/_at via a single CASE-WHEN.
    def bulk_store_written_values(prepared)
      if prepared.empty?
        return
      end

      now    = Time.current
      mp_ids = prepared.map { |e| e[:measurement_point].id }

      value_cases = prepared.map do |entry|
        mp         = entry[:measurement_point]
        serialized = mp.serialize_for_storage(entry[:raw_value])
        "WHEN #{mp.id.to_i} THEN #{ActiveRecord::Base.connection.quote(serialized)}"
      end.join(' ')

      MeasurementPoint.where(id: mp_ids).update_all(
        "last_decoded_value = CASE id #{value_cases} END, " \
        "last_decoded_value_at = #{ActiveRecord::Base.connection.quote(now)}, " \
        "updated_at = #{ActiveRecord::Base.connection.quote(now)}"
      )
    end

    # Bulk-insert one ModbusWriteLog per prepared entry. Target is
    # polymorphic: the Plc or ModbusDevice that holds the register.
    # relay_host_plc_id is set only for relay-write topology.
    # Logging failures do not break the write operation.
    def bulk_log_writes(prepared, old_values, context)
      if prepared.empty?
        return
      end

      now = Time.current
      rows = prepared.map do |entry|
        mp     = entry[:measurement_point]
        target = mp.write_target
        relay  = mp.relay_host_plc

        {
          target_type:          target&.class&.name,
          target_id:            target&.id,
          relay_host_plc_id:    relay&.id,
          site_id:              mp.site_id,
          user_id:              context.user&.id,
          measurement_point_id: mp.id,
          register_template_id: mp.register_template_id,
          source:               context.source,
          old_value:            old_values[mp.id],
          new_value:            mp.serialize_for_storage(entry[:raw_value]),
          batch_id:             context.batch_id,
          created_at:           now
        }
      end

      begin
        ModbusWriteLog.insert_all(rows)
      rescue => e
        Rails.logger.error("Failed to bulk insert ModbusWriteLogs: #{e.message}")
      end
    end

    # Touch every gateway, every target, and every relay host involved
    # in this batch. Each entity gets touched at most once per call via
    # set deduplication and per-class update_all.
    def touch_endpoints!(prepared)
      now             = Time.current
      gateway_ids     = Set.new
      plc_target_ids  = Set.new
      device_target_ids = Set.new
      relay_host_ids  = Set.new

      prepared.each do |entry|
        mp = entry[:measurement_point]

        gateway_ids << entry[:write_coordinates].gateway.id

        target = mp.write_target
        case target
        when Plc
          plc_target_ids << target.id
        when ModbusDevice
          device_target_ids << target.id
        end

        relay = mp.relay_host_plc
        if relay.present?
          relay_host_ids << relay.id
        end
      end

      if gateway_ids.any?
        Gateway.where(id: gateway_ids.to_a).update_all(last_seen_at: now)
      end

      # Merge PLC targets and relay hosts - both touch Plc rows.
      all_plc_ids = (plc_target_ids | relay_host_ids).to_a
      if all_plc_ids.any?
        Plc.where(id: all_plc_ids).update_all(last_seen_at: now)
      end

      if device_target_ids.any?
        ModbusDevice.where(id: device_target_ids.to_a).update_all(last_seen_at: now)
      end
    end

    # Behavior orchestration uses the host PLC (the one running the
    # firmware whose behavior governs writes). For relay writes that's
    # the host Eliwell; for direct PLC writes that's the PLC itself; for
    # gateway-direct ModbusDevice writes there's no PLC (returns nil).
    def behavior_host_plc_for(mp)
      mp.relay_host_plc || mp.plc
    end

    def validate_writable!(mp)
      if mp.register_template.read_only?
        raise ValidationError,
          "Register '#{mp.register_template.label}' is read-only"
      end
    end

    def validate_bounds!(mp, raw_value)
      rt = mp.register_template
      if !rt.numeric_register?
        return
      end

      if !rt.value_in_bounds?(raw_value.to_f)
        raise ValidationError,
          "Value out of range (#{rt.min_value}..#{rt.max_value})"
      end
    end
end
