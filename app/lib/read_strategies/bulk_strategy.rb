# Strategy: :bulk.
#
# Collapses registers sharing a bulk_read_group into one Modbus read,
# against the PLC's own address space. Each group reads only the span its
# members occupy (min_offset..max_end), not the entire group from offset 0 -
# several groups may share the same bulk_read_address but cover disjoint
# slices. Groups exceeding MODBUS_MAX_READ_REGISTERS are split into chunks;
# each member is later resolved to its specific chunk by offset arithmetic.
#
# This is the existing PLC-native logic, lifted out of VpnManagerClient.
#
module ReadStrategies
  class BulkStrategy < Base
    MAX_REGISTERS = VpnManagerClient::MODBUS_MAX_READ_REGISTERS

    def reads
      build!
      @reads
    end

    def resolve(raw_results)
      build!
      results = {}

      @pairs.each do |mp, coords|
        if coords.template_bulk_group.present?
          group = @groups[coords.template_bulk_group]
          chunk_result, offset_in_chunk = locate_chunk(raw_results, coords, group)
          results[mp.id] = read_slice(
            chunk_result, offset_in_chunk, coords.count,
            "bulk read group '#{coords.template_bulk_group}'"
          )
        else
          result = raw_results[mp.id.to_s]
          if result.nil?
            next
          end

          results[mp.id] = result
        end
      end

      results
    end

    private
      def build!
        if @reads
          return
        end

        @reads = []
        @groups = {}
        individuals = []

        @pairs.each do |mp, coords|
          if coords.template_bulk_group.present?
            @groups[coords.template_bulk_group] ||= {
              register_type:      coords.register_type,
              members:            [],
              template_bulk_base: coords.template_bulk_base
            }
            @groups[coords.template_bulk_group][:members] << [mp, coords]
          else
            individuals << [mp, coords]
          end
        end

        @groups.each do |group_name, data|
          offsets_and_counts = data[:members].map { |_mp, c| [c.template_bulk_offset, c.count] }
          min_offset = offsets_and_counts.map(&:first).min
          max_end    = offsets_and_counts.map { |o, c| o + c }.max
          span       = max_end - min_offset
          base_address = data[:template_bulk_base] + min_offset

          data[:min_offset]   = min_offset
          data[:base_address] = base_address
          data[:span]         = span

          if span <= MAX_REGISTERS
            @reads << {
              id:            "group:#{group_name}",
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
                id:            "group:#{group_name}:#{chunk_index}",
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

        individuals.each do |mp, coords|
          @reads << {
            id:            mp.id.to_s,
            register_type: coords.register_type,
            address:       coords.address,
            count:         coords.count
          }
        end
      end

      def locate_chunk(raw_results, coords, group)
        adjusted_offset = coords.template_bulk_offset - group[:min_offset]

        if group[:chunk_count] == 1
          [raw_results["group:#{coords.template_bulk_group}"], adjusted_offset]
        else
          chunk_index     = adjusted_offset / MAX_REGISTERS
          offset_in_chunk = adjusted_offset % MAX_REGISTERS
          [raw_results["group:#{coords.template_bulk_group}:#{chunk_index}"], offset_in_chunk]
        end
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
