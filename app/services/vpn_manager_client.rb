class VpnManagerClient
  include HTTParty
  base_uri ENV['VPN_MANAGER_BASE_URL']

  class Error < StandardError; end
  class ConnectionError < Error; end
  class AuthenticationError < Error; end
  class NotFoundError < Error; end

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
  #
  # For registers without a bulk_read_group, falls back to individual reads.
  def bulk_read_registers(plc, measurement_points)
    gateway = plc.gateway
    reads = build_reads(measurement_points)

    response = post('/api/v1/modbus/bulk_read', {
      gateway_label: gateway.label,
      target_ip: plc.private_ip,
      slave_id: plc.slave_id,
      reads: reads
    })

    parse_bulk_response(response, measurement_points)
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

  # Writes registers for a single PLC through its gateway
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

    response = post('/api/v1/modbus/bulk_write', {
      gateway_label: gateway.label,
      target_ip: plc.private_ip,
      slave_id: plc.slave_id,
      writes: writes
    })

    parse_bulk_response_simple(response)
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

      # One read per bulk_read_group
      grouped.each do |group_name, group_data|
        # Calculate total register count needed for this group
        max_end = group_data[:members].map do |mp|
          rt = mp.register_template
          rt.bulk_read_offset + rt.address_count
        end.max

        address = group_data[:address] + MODBUS_ADDRESS_OFFSET
        reads << {
          id: "group:#{group_name}",
          register_type: group_data[:register_type],
          address: address,
          count: max_end
        }
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

      reads
    end

    # Parse response and fan out group reads to individual measurement points
    def parse_bulk_response(response, measurement_points)
      raw_results = {}
      response['results']&.each do |result|
        raw_results[result['id']] = result
      end

      results = {}

      measurement_points.each do |mp|
        rt = mp.register_template

        if rt.bulk_read_group.present?
          # Extract this MP's slice from the group read response
          group_result = raw_results["group:#{rt.bulk_read_group}"]

          if group_result && group_result['status'] == 'ok' && group_result['values'].present?
            offset = rt.bulk_read_offset
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
                error: "Incomplete data in bulk read group '#{rt.bulk_read_group}' at offset #{offset}"
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
          # Individual read - direct mapping
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

      {
        success: response['status'] == 'ok',
        sample_time: response['sample_time'],
        error: response['error'],
        error_type: response['error_type'],
        results: results
      }
    end

    # Simple response parser for writes (no group fan-out needed)
    def parse_bulk_response_simple(response)
      results = {}
      response['results']&.each do |result|
        mp_id = result['id'].to_i
        results[mp_id] = {
          status: result['status'],
          values: result['values'],
          error: result['error']
        }
      end

      {
        success: response['status'] == 'ok',
        sample_time: response['sample_time'],
        error: response['error'],
        error_type: response['error_type'],
        results: results
      }
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
