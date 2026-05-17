# Strategy: :relay_contiguous.
#
# Used by host firmwares whose `relay_read_strategy` is 'relay_contiguous'.
# The host mirrors each peripheral into a fixed slot in its own register space:
# slot N occupies [relay_slot_base + relay_slot_size * N, slot end). Within
# a slot, registers are placed at offsets defined by ModbusFirmwareRelayMapping.
#
# Reads min..max per slot (one read per slot, split at MODBUS_MAX_READ_REGISTERS
# if needed). Sparse slots read fewer registers than the full slot size.
#
module ReadStrategies
  class RelayContiguousStrategy < Base
    MAX_REGISTERS = VpnManagerClient::MODBUS_MAX_READ_REGISTERS

    def reads
      build!
      @reads
    end

    def resolve(raw_results)
      build!
      results = {}

      @pairs.each do |mp, coords|
        slot  = coords.relay_slot_number
        group = @groups[slot]
        if group.nil?
          next
        end

        offset_in_read = coords.address - group[:base_address]

        if group[:chunk_count] == 1
          chunk_id        = slot_id(slot)
          offset_in_chunk = offset_in_read
        else
          chunk_index     = offset_in_read / MAX_REGISTERS
          offset_in_chunk = offset_in_read % MAX_REGISTERS
          chunk_id        = chunk_slot_id(slot, chunk_index)
        end

        results[mp.id] = read_slice(raw_results[chunk_id], offset_in_chunk, coords.count, "relay slot #{slot}")
      end

      results
    end

    private
      def build!
        if @reads
          return
        end

        @reads  = []
        @groups = {}

        @pairs.each do |_mp, coords|
          @groups[coords.relay_slot_number] ||= {
            register_type: coords.register_type,
            entries:       []
          }
          @groups[coords.relay_slot_number][:entries] << [coords.address, coords.count]
        end

        @groups.each do |slot, data|
          base_address = data[:entries].map(&:first).min
          max_end      = data[:entries].map { |a, c| a + c }.max
          span         = max_end - base_address

          data[:base_address] = base_address
          data[:span]         = span

          if span <= MAX_REGISTERS
            @reads << {
              id:            slot_id(slot),
              register_type: data[:register_type],
              address:       base_address,
              count:         span
            }
            data[:chunk_count] = 1
          else
            chunk_index = 0
            offset      = 0
            while offset < span
              chunk_count = [MAX_REGISTERS, span - offset].min
              @reads << {
                id:            chunk_slot_id(slot, chunk_index),
                register_type: data[:register_type],
                address:       base_address + offset,
                count:         chunk_count
              }
              offset += MAX_REGISTERS
              chunk_index += 1
            end
            data[:chunk_count] = chunk_index
          end
        end
      end

      def slot_id(slot)
        "slot:#{slot}"
      end

      def chunk_slot_id(slot, chunk_index)
        "slot:#{slot}:#{chunk_index}"
      end

      def read_slice(chunk_result, offset_in_chunk, count, label)
        if chunk_result.nil?
          return { status: 'error', values: nil, error: "No response for #{label}" }
        end

        if chunk_result[:status] != 'ok' || chunk_result[:values].blank?
          return {
            status: chunk_result[:status] || 'error',
            values: nil,
            error:  chunk_result[:error]  || "No response for #{label}"
          }
        end

        slice = chunk_result[:values][offset_in_chunk, count]
        if slice.nil? || slice.length != count
          return {
            status: 'error',
            values: nil,
            error:  "Incomplete data in #{label} at offset #{offset_in_chunk}"
          }
        end

        { status: 'ok', values: slice, error: nil }
      end
  end
end
