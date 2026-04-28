# Abstract base for read strategies. Takes a homogeneous list of
# (MeasurementPoint, ModbusCoordinates) pairs all using the same bulk_strategy.
#
# #reads   -> Array<{ id:, register_type:, address:, count: }> in wire format
# #resolve -> distributes a results-by-id hash back to per-MP results
#             { mp_id => { status:, values:, error: } }
#
module ReadStrategies
  class Base
    attr_reader :pairs

    def initialize(pairs)
      @pairs = pairs
    end

    def reads
      raise NotImplementedError
    end

    def resolve(_raw_results)
      raise NotImplementedError
    end
  end
end
