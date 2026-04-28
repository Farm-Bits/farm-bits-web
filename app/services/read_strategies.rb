# Top-level resolver for bulk_strategy -> strategy class.
#
# Built-in non-relay strategies are listed here. Relay strategies are
# delegated to RelayReadStrategyRegistry so adding a new relay layout is
# a single-file change.
#
module ReadStrategies
  BUILTINS = {
    individual: 'ReadStrategies::IndividualStrategy',
    bulk:       'ReadStrategies::BulkStrategy'
  }.freeze

  def self.resolve(strategy)
    sym = strategy.to_sym

    builtin = BUILTINS[sym]
    if builtin.present?
      return builtin.constantize
    end

    RelayReadStrategyRegistry.strategy_for(sym)
  end
end
