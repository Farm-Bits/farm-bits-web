class ReadStrategy
  attr_reader :pairs, :strategy

  def initialize(strategy_impl:, strategy:)
    @strategy_impl = strategy_impl
    @strategy      = strategy.to_s
    @pairs         = strategy_impl.pairs
  end

  def reads
    prefix = "#{@strategy}::"
    @strategy_impl.reads.map { |r| r.merge(id: "#{prefix}#{r[:id]}") }
  end

  def resolve(merged_raw_results)
    prefix = "#{@strategy}::"
    own = {}
    merged_raw_results.each do |id, result|
      str = id.to_s
      if str.start_with?(prefix)
        own[str.sub(prefix, '')] = result
      end
    end
    @strategy_impl.resolve(own)
  end
end
