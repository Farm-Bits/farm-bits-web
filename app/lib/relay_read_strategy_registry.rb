# Registry of pluggable relay read strategies. ModbusFirmwareVersion's
# `relay_read_strategy` field is validated against STRATEGIES.
#
# Adding a new relay layout means:
#   1. Add the symbol to STRATEGIES
#   2. Add the strategy class to REGISTRY
#   3. Implement the strategy under app/services/read_strategies/
#
module RelayReadStrategyRegistry
  STRATEGIES = %w[relay_contiguous].freeze

  REGISTRY = {
    relay_contiguous: 'ReadStrategies::RelayContiguousStrategy'
  }.freeze

  def self.strategy_for(strategy)
    klass_name = REGISTRY[strategy.to_sym]
    if klass_name.nil?
      return nil
    end

    klass_name.constantize
  end
end
