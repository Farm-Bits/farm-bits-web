# Strategy: :individual.
#
# One wire read per MeasurementPoint, against the PLC's (or gateway-direct
# peripheral's) own address space. Used when no bulk_read_group metadata is
# present on the register templates - typically gateway-direct ModbusDevices
# whose firmwares don't bother with bulk-read optimization, or PLC-native
# MPs that haven't been assigned to a group.
#
module ReadStrategies
  class IndividualStrategy < Base
    def reads
      @reads ||= @pairs.map do |mp, coords|
        {
          id:            mp.id.to_s,
          register_type: coords.register_type,
          address:       coords.address,
          count:         coords.count
        }
      end
    end

    def resolve(raw_results)
      results = {}

      @pairs.each do |mp, _coords|
        result = raw_results[mp.id.to_s]
        if result.nil?
          next
        end

        results[mp.id] = result
      end

      results
    end
  end
end
