class VpnManagerClient
  include HTTParty
  base_uri ENV['VPN_MANAGER_BASE_URL']

  class Error               < StandardError; end
  class ConnectionError     < Error; end
  class AuthenticationError < Error; end
  class NotFoundError       < Error; end

  # Modbus protocol limit: max registers per single read (FC 3/4).
  MODBUS_MAX_READ_REGISTERS = 125

  # Max read/write entries per HTTP request to the VPN manager. Keeps each
  # POST well within the 30s HTTP timeout.
  MAX_READS_PER_REQUEST  = 10
  MAX_WRITES_PER_REQUEST = 10

  def initialize
    @api_token = ENV['VPN_MANAGER_API_TOKEN']
  end

  # Generic bulk Modbus read at a given endpoint. Reads are pre-built by the
  # caller (typically ModbusEndpointReadService via ReadStrategies).
  #
  # @return [Hash] { success:, sample_time:, error:, error_type:, results: }
  #   results is { read_id_string => { 'status' =>, 'values' =>, 'error' => } }
  def bulk_read_registers(gateway_label:, target_ip:, slave_id:, reads:)
    read_batches      = reads.each_slice(MAX_READS_PER_REQUEST).to_a
    merged_results    = {}
    last_response_meta = {}

    read_batches.each_with_index do |batch, batch_index|
      Rails.logger.info(
        "[bulk_read_registers] #{gateway_label} #{target_ip}/#{slave_id}: " \
        "batch #{batch_index + 1}/#{read_batches.size} (#{batch.size} reads)"
      )

      response = post('/api/v1/modbus/bulk_read', {
        gateway_label: gateway_label,
        target_ip:     target_ip,
        slave_id:      slave_id,
        reads:         batch
      })

      last_response_meta = {
        success:     response['status'] == 'ok',
        sample_time: response['sample_time'],
        error:       response['error'],
        error_type:  response['error_type']
      }

      response['results']&.each do |result|
        merged_results[result['id']] = result
      end

      if response['status'] != 'ok' && response['error_type'] == 'connection'
        break
      end
    end

    last_response_meta.merge(results: merged_results)
  end

  # Generic bulk Modbus write at a given endpoint. Writes are pre-built by
  # the caller.
  #
  # @param writes [Array<Hash>] [{ id:, register_type:, address:, values: }, ...]
  # @return [Hash] { success:, error:, error_type:, results: }
  #   results is { mp_id_int => { status:, values:, error: } }
  def bulk_write_registers(gateway_label:, target_ip:, slave_id:, writes:)
    if !write_enabled?
      return {
        success:    true,
        error:      nil,
        error_type: nil,
        results:    writes.each_with_object({}) do |entry, hash|
          hash[entry[:id]] = {
            status: 'ok',
            values: entry[:values],
            error:  nil
          }
        end
      }
    end

    write_batches      = writes.each_slice(MAX_WRITES_PER_REQUEST).to_a
    merged_results     = {}
    last_response_meta = {}

    write_batches.each_with_index do |batch, batch_index|
      Rails.logger.info(
        "[bulk_write_registers] #{gateway_label} #{target_ip}/#{slave_id}: " \
        "batch #{batch_index + 1}/#{write_batches.size} (#{batch.size} writes)"
      )

      response = post('/api/v1/modbus/bulk_write', {
        gateway_label: gateway_label,
        target_ip:     target_ip,
        slave_id:      slave_id,
        writes:        batch
      })

      last_response_meta = {
        success:    response['status'] == 'ok',
        error:      response['error'],
        error_type: response['error_type']
      }

      response['results']&.each do |result|
        merged_results[result['id'].to_i] = {
          status: result['status'],
          values: result['values'],
          error:  result['error']
        }
      end

      if response['status'] != 'ok' && response['error_type'] == 'connection'
        break
      end
    end

    last_response_meta.merge(results: merged_results)
  end

  private
    def post(path, body)
      response = self.class.post(path, {
        headers: {
          'Content-Type'  => 'application/json',
          'Authorization' => "Bearer #{@api_token}"
        },
        body:         body.to_json,
        timeout:      30,
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
