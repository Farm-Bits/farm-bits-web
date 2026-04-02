class VpnManagerClient
  include HTTParty
  base_uri ENV['VPN_MANAGER_BASE_URL']

  class Error < StandardError; end
  class ConnectionError < Error; end
  class AuthenticationError < Error; end
  class NotFoundError < Error; end

  # Modbus protocol limit: max registers per single read (FC 3/4).
  # The true Modbus spec allows up to 125 registers per read.
  # Groups exceeding this are split into multiple reads.
  MODBUS_MAX_READ_REGISTERS = 125

  # Max read/write entries per HTTP request to the VPN manager.
  # Each entry triggers one or more Modbus transactions on the wire,
  # so keeping this bounded ensures each POST completes well within
  # the 30s HTTP timeout.
  MAX_READS_PER_REQUEST  = 10
  MAX_WRITES_PER_REQUEST = 10

  def initialize
    @api_token = ENV['VPN_MANAGER_API_TOKEN']
  end

  def read_register(measurement_point)
    plc = measurement_point.plc
    gateway = plc.gateway

    address = measurement_point.register_template.address + MODBUS_ADDRESS_OFFSET

    post('/api/v1/modbus/read', {
      gateway_label: gateway.label,
      target_ip: plc.private_ip,
      slave_id: plc.slave_id,
      register_type: measurement_point.register_template.register_type,
      address: address,
      count: measurement_point.register_template.address_count
    })
  end

  # Reads registers for a single PLC through its gateway.
  #
  # Automatically groups measurement points by bulk_read_group when available,
  # sending a single Modbus read per group instead of one per register.
  # Each group only reads its actual register span (min_offset..max_end),
  # not the full range from offset 0.
  #
  # For registers without a bulk_read_group, falls back to individual reads.
  #
  # Reads are batched into separate HTTP requests (max MAX_READS_PER_REQUEST
  # each) to avoid VPN manager timeouts when many groups need to be read.
  def bulk_read_registers(plc, measurement_points)
    gateway = plc.gateway
    reads, group_offsets = build_reads(measurement_points)
    read_batches = reads.each_slice(MAX_READS_PER_REQUEST).to_a

    merged_results = {}
    last_response_meta = {}

    read_batches.each_with_index do |batch, batch_index|
      Rails.logger.info(
        "PLC #{plc.id}: sending read batch #{batch_index + 1}/#{read_batches.size} " \
        "(#{batch.size} reads: #{batch.map { |r| r[:id] }.join(', ')})"
      )

      response = post('/api/v1/modbus/bulk_read', {
        gateway_label: gateway.label,
        target_ip: plc.private_ip,
        slave_id: plc.slave_id,
        reads: batch
      })

      last_response_meta = {
        success: response['status'] == 'ok',
        sample_time: response['sample_time'],
        error: response['error'],
        error_type: response['error_type']
      }

      response['results']&.each do |result|
        merged_results[result['id']] = result
      end

      # Stop sending further batches if the connection is broken
      if response['status'] != 'ok' && response['error_type'] == 'connection'
        break
      end
    end

    parse_bulk_response(merged_results, measurement_points, last_response_meta, group_offsets)
  end

  def write_register(measurement_point, value)
    plc = measurement_point.plc
    gateway = plc.gateway

    address = measurement_point.register_template.address + MODBUS_ADDRESS_OFFSET

    if !write_enabled?
      return {
        status: 'ok',
        gateway_label: gateway.label,
        target_ip: plc.private_ip,
        slave_id: plc.slave_id.to_i,
        timestamp: Time.current.iso8601,
        result: {
          id: nil,
          status: 'ok'
        }
      }
    end

    post('/api/v1/modbus/write', {
      gateway_label: gateway.label,
      target_ip: plc.private_ip,
      slave_id: plc.slave_id,
      register_type: measurement_point.register_template.register_type,
      address: address,
      values: measurement_point.register_template.encode_value(value)
    })
  end

  # Writes registers for a single PLC through its gateway.
  #
  # Chunks writes into separate HTTP requests (max MAX_WRITES_PER_REQUEST each)
  # to stay within Modbus protocol limits and avoid VPN manager timeouts.
  def bulk_write_registers(plc, measurement_points_with_values)
    gateway = plc.gateway

    writes = measurement_points_with_values.map do |entry|
      measurement_point = entry[:measurement_point]
      register_template = measurement_point.register_template
      address = register_template.address + MODBUS_ADDRESS_OFFSET

      {
        id: measurement_point.id,
        register_type: register_template.register_type,
        address: address,
        values: register_template.encode_value(entry[:value])
      }
    end

    if !write_enabled?
      return {
        success: true,
        sample_time: Time.current.iso8601,
        error: nil,
        error_type: nil,
        results: writes.each_with_object({}) do |entry, hash|
          hash[entry[:id]] = {
            status: 'ok',
            values: entry[:values],
            error: nil
          }
        end
      }
    end

    write_batches = writes.each_slice(MAX_WRITES_PER_REQUEST).to_a
    merged_results = {}
    last_response_meta = {}

    write_batches.each do |batch|
      response = post('/api/v1/modbus/bulk_write', {
        gateway_label: gateway.label,
        target_ip: plc.private_ip,
        slave_id: plc.slave_id,
        writes: batch
      })

      last_response_meta = {
        success: response['status'] == 'ok',
        sample_time: response['sample_time'],
        error: response['error'],
        error_type: response['error_type']
      }

      response['results']&.each do |result|
        mp_id = result['id'].to_i
        merged_results[mp_id] = {
          status: result['status'],
          values: result['values'],
          error: result['error']
        }
      end

      if response['status'] != 'ok' && response['error_type'] == 'connection'
        break
      end
    end

    last_response_meta.merge(results: merged_results)
  end

  private
    # Build the reads array, merging registers that share a bulk_read_group
    # into a single read request.
    #
    # How bulk_read_group works:
    #   - bulk_read_group:   a string key grouping contiguous registers (e.g. "analog_inputs")
    #   - bulk_read_address: the starting Modbus address for the entire group
    #   - bulk_read_offset:  the offset (in registers) within the group where this
    #                        register's data starts
    #
    # Example: 3 registers in group "analog_inputs" with bulk_read_address=100
    #   Register A: bulk_read_offset=0, address_count=2  → values[0..1]
    #   Register B: bulk_read_offset=2, address_count=1  → values[2]
    #   Register C: bulk_read_offset=3, address_count=2  → values[3..4]
    #   → Single read: address=100, count=5
    #
    # Groups exceeding MODBUS_MAX_READ_REGISTERS are split into chunks.
    # Each MP is later resolved to its specific chunk in parse_bulk_response.
    #
    # IMPORTANT: Each group only reads the register span its members actually
    # occupy (min_offset..max_end), not from offset 0. This avoids redundant
    # reads when multiple groups share the same bulk_read_address but occupy
    # different slices of the address space (e.g. do1_om_config..do12_om_config
    # all share bulk_read_address=16554 but each occupies a disjoint 189-register
    # slice). Without this, each group would re-read all preceding groups' data.
    #
    # Returns [reads, group_offsets] where group_offsets maps group names to
    # their min_offset, needed by parse_bulk_response for correct value extraction.
    #
    def build_reads(measurement_points)
      grouped = {}
      individual = []

      measurement_points.each do |mp|
        rt = mp.register_template

        if rt.bulk_read_group.present?
          grouped[rt.bulk_read_group] ||= {
            register_type: rt.register_type,
            address: rt.bulk_read_address,
            members: []
          }
          grouped[rt.bulk_read_group][:members] << mp
        else
          individual << mp
        end
      end

      reads = []
      group_offsets = {}

      grouped.each do |group_name, group_data|
        offsets_and_counts = group_data[:members].map do |mp|
          rt = mp.register_template
          [rt.bulk_read_offset, rt.address_count]
        end

        min_offset = offsets_and_counts.map(&:first).min
        max_end = offsets_and_counts.map { |o, c| o + c }.max
        span = max_end - min_offset

        group_offsets[group_name] = min_offset

        base_address = group_data[:address] + MODBUS_ADDRESS_OFFSET + min_offset

        if span <= MODBUS_MAX_READ_REGISTERS
          reads << {
            id: "group:#{group_name}",
            register_type: group_data[:register_type],
            address: base_address,
            count: span
          }
        else
          chunk_index = 0
          offset = 0

          while offset < span
            chunk_count = [MODBUS_MAX_READ_REGISTERS, span - offset].min

            reads << {
              id: "group:#{group_name}:#{chunk_index}",
              register_type: group_data[:register_type],
              address: base_address + offset,
              count: chunk_count
            }

            offset += MODBUS_MAX_READ_REGISTERS
            chunk_index += 1
          end
        end
      end

      # One read per individual register (no bulk_read_group)
      individual.each do |mp|
        rt = mp.register_template
        address = rt.address + MODBUS_ADDRESS_OFFSET
        reads << {
          id: mp.id.to_s,
          register_type: rt.register_type,
          address: address,
          count: rt.address_count
        }
      end

      [reads, group_offsets]
    end

    # Parse merged results from all batches and fan out group reads to
    # individual measurement points.
    #
    # Handles two group ID formats:
    #   - "group:name"   → small group read in one shot
    #   - "group:name:N" → chunk N of a split group
    #
    # Each MP resolves directly to its chunk, so a failed chunk only
    # affects the MPs whose offsets fall within that chunk's range.
    #
    # group_offsets maps each group name to its min_offset. MP offsets
    # are adjusted by subtracting min_offset before chunk resolution,
    # since reads start from min_offset rather than 0.
    def parse_bulk_response(raw_results, measurement_points, response_meta, group_offsets)
      results = {}

      measurement_points.each do |mp|
        rt = mp.register_template

        if rt.bulk_read_group.present?
          group_result, offset = resolve_group_result(raw_results, rt, group_offsets)

          if group_result && group_result['status'] == 'ok' && group_result['values'].present?
            count = rt.address_count
            mp_values = group_result['values'][offset, count]

            if mp_values && mp_values.length == count
              results[mp.id] = {
                status: 'ok',
                values: mp_values,
                error: nil
              }
            else
              results[mp.id] = {
                status: 'error',
                values: nil,
                error: "Incomplete data in bulk read group '#{rt.bulk_read_group}' at offset #{rt.bulk_read_offset}"
              }
            end
          else
            results[mp.id] = {
              status: group_result&.dig('status') || 'error',
              values: nil,
              error: group_result&.dig('error') || 'No response for bulk read group'
            }
          end
        else
          individual_result = raw_results[mp.id.to_s]
          if individual_result
            results[mp.id] = {
              status: individual_result['status'],
              values: individual_result['values'],
              error: individual_result['error']
            }
          end
        end
      end

      response_meta.merge(results: results)
    end

    # Find the right result entry and offset for a group member.
    #
    # For small groups (single read), returns the group result with the
    # offset adjusted relative to min_offset.
    #
    # For chunked groups, calculates which chunk the MP falls into and
    # returns that chunk's result with the offset adjusted to be relative
    # to the chunk start.
    #
    # All offsets are first shifted by -min_offset so they are relative to
    # the actual start of the read range rather than bulk_read_address.
    def resolve_group_result(raw_results, register_template, group_offsets)
      group_name = register_template.bulk_read_group
      min_offset = group_offsets[group_name] || 0
      adjusted_offset = register_template.bulk_read_offset - min_offset

      # Try single-read format first
      single_result = raw_results["group:#{group_name}"]
      if single_result
        return [single_result, adjusted_offset]
      end

      # Chunked format — resolve to the specific chunk
      chunk_index = adjusted_offset / MODBUS_MAX_READ_REGISTERS
      offset_in_chunk = adjusted_offset % MODBUS_MAX_READ_REGISTERS
      chunk_result = raw_results["group:#{group_name}:#{chunk_index}"]

      [chunk_result, offset_in_chunk]
    end

    def post(path, body)
      response = self.class.post(path, {
        headers: {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{@api_token}"
        },
        body: body.to_json,
        timeout: 30,
        open_timeout: 10
      })

      handle_response(response)
    end

    def handle_response(response)
      case response.code
      when 200..299
        response.parsed_response
      when 401
        raise AuthenticationError, 'Invalid API token'
      when 404
        raise NotFoundError, response.parsed_response&.dig('error') || 'Not found'
      when 503
        raise ConnectionError, response.parsed_response&.dig('error') || 'Service unavailable'
      else
        parsed = response.parsed_response
        case parsed
        when Hash
          raise Error, parsed.dig('error')
        when String
          raise Error, parsed.presence
        end
      end
    end

    def write_enabled?
      Rails.env.production? || ENV['ENABLE_WRITE_VPN_MANAGER'] == 'true'
    end
end
