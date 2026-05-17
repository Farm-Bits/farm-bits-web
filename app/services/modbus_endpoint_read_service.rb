# Reads a set of MeasurementPoints that all terminate at the same Modbus
# endpoint (gateway + target_ip + slave_id) in a single VPN-manager request.
# Topology-agnostic - drives every read path (PLC-native, gateway-direct,
# PLC-relayed) through ReadCoordinates and the planner registry.
#
# Pipeline:
#   1. Compute coordinates per MP (skip nil)
#   2. Group by bulk_strategy, build one ReadPlan per strategy
#   3. Send all strategies' reads in one HTTP call (IDs namespaced by strategy)
#   4. Resolve each plan, decode via RegisterTemplate#decode_data
#   5. Hand decoded readings to BulkRecordingService for storage
#
class ModbusEndpointReadService
  def initialize(gateway:, target_ip:, slave_id:, measurement_points:)
    @gateway            = gateway
    @target_ip          = target_ip
    @slave_id           = slave_id
    @measurement_points = measurement_points
  end

  def call
    pairs = build_pairs
    if pairs.empty?
      return false
    end

    plans = build_plans(pairs)
    if plans.empty?
      return false
    end

    response = client.bulk_read_registers(
      gateway_label: @gateway.label,
      target_ip:     @target_ip,
      slave_id:      @slave_id,
      reads:         plans.flat_map(&:reads)
    )

    sample_time = parse_sample_time(response[:sample_time])
    raw_results = response[:results] || {}

    readings = []
    plans.each do |plan|
      per_mp = plan.resolve(raw_results)
      failures = []

      plan.pairs.each do |mp, _coords|
        result = per_mp[mp.id]
        if result.nil?
          failures << { mp_id: mp.id, mp_name: mp.name, error: 'no result returned' }
          next
        end

        if result[:status] == 'ok' && result[:values].present?
          begin
            decoded = mp.register_template.decode_data(result[:values])
            readings << { measurement_point: mp, value: decoded, sample_time: sample_time }
          rescue => e
            failures << { mp_id: mp.id, mp_name: mp.name, error: "decode: #{e.class} - #{e.message}" }
            Rails.logger.warn(
              "ModbusEndpointReadService: decode failed for MP #{mp.id} (#{mp.name}): #{e.class} - #{e.message}"
            )
          end
        else
          failures << { mp_id: mp.id, mp_name: mp.name, error: result[:error] }
          Rails.logger.warn(
            "ModbusEndpointReadService: read failed for MP #{mp.id} (#{mp.name}): #{result[:error]}"
          )
        end
      end

      if failures.any? && relay_strategy?(plan.strategy)
        notify_relay_failure(plan, failures)
      end
    end

    BulkRecordingService.new(readings).call
    true
  end

  private
    def build_pairs
      @measurement_points
        .map { |mp| [mp, mp.read_coordinates] }
        .reject { |_mp, coords| coords.nil? }
    end

    def build_plans(pairs)
      pairs.group_by { |_mp, coords| coords.bulk_strategy }.map do |strategy, group|
        klass = ReadStrategies.resolve(strategy)
        if klass.nil?
          Rails.logger.warn("ModbusEndpointReadService: unknown bulk_strategy #{strategy.inspect}")
          next
        end

        ReadStrategy.new(strategy_impl: klass.new(group), strategy: strategy)
      end.compact
    end

    def client
      @client ||= VpnManagerClient.new
    end

    def parse_sample_time(value)
      if value.blank?
        return Time.current
      end

      Time.parse(value)
    rescue ArgumentError => e
      Rails.logger.warn("ModbusEndpointReadService: bad sample_time '#{value}': #{e.message}")
      Time.current
    end

    def relay_strategy?(strategy)
      RelayReadStrategyRegistry::STRATEGIES.include?(strategy.to_s)
    end

    def notify_relay_failure(plan, failures)
      Rails.logger.error(
        "ModbusEndpointReadService: relay read failures on strategy '#{plan.strategy}' " \
        "at #{@gateway.label}/#{@target_ip}/#{@slave_id}: #{failures.size} MP(s) failed"
      )

      Bugsnag.notify("Relay read failures on strategy '#{plan.strategy}'") do |report|
        report.severity = 'warning'
        report.add_metadata(:relay_read, {
          strategy:      plan.strategy,
          gateway_label: @gateway.label,
          target_ip:     @target_ip,
          slave_id:      @slave_id,
          failure_count: failures.size,
          failures:      failures.first(20)
        })
      end
    rescue => e
      Rails.logger.error("ModbusEndpointReadService: failed to report relay failure: #{e.message}")
    end
end
