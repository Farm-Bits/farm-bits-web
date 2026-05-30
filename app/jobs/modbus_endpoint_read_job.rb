# Pure executor: reads the given MeasurementPoints via ModbusEndpointReadService.
# No scheduling logic - callers decide which MPs need reading.
#
# Accepts MP IDs only; endpoints are resolved fresh from each MP's
# read_coordinates so concurrent topology changes (e.g. gateway reassignment
# between enqueue and execution) are handled correctly. MPs that resolve to
# different endpoints than expected are processed as separate groups, with
# a warning.
#
# Callers:
#   - ModbusPollingJob (via ModbusReadEnqueuer)
#   - ModbusRefreshJob (via ModbusReadEnqueuer)
#   - any code needing on-demand reads (via ModbusReadEnqueuer)
#
class ModbusEndpointReadJob
  include Sidekiq::Job
  sidekiq_options queue: 'default', retry: false

  def perform(measurement_point_ids)
    mps = MeasurementPoint
      .where(id: measurement_point_ids)
      .includes(*MeasurementPoint::READ_COORDINATES_INCLUDES)
      .to_a
      .select { |mp| mp.read_coordinates.present? }
    if mps.empty?
      return
    end

    by_endpoint = mps.group_by { |mp| mp.read_coordinates.endpoint_key }
    if by_endpoint.size > 1
      Rails.logger.warn(
        "ModbusEndpointReadJob: #{measurement_point_ids.size} MPs resolved to " \
        "#{by_endpoint.size} endpoints; processing each separately"
      )
    end

    by_endpoint.each_value do |group|
      coords = group.first.read_coordinates
      ModbusEndpointReadService.new(
        gateway:            coords.gateway,
        target_ip:          coords.target_ip,
        slave_id:           coords.slave_id,
        measurement_points: group
      ).call
    end
  rescue VpnManagerClient::ConnectionError => e
    Rails.logger.error("ModbusEndpointReadJob connection error: #{e.message}")
    raise
  rescue VpnManagerClient::NotFoundError => e
    Rails.logger.error("ModbusEndpointReadJob not found: #{e.message}")
    raise
  rescue => e
    Rails.logger.error("ModbusEndpointReadJob #{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace&.first(10)&.join("\n"))
    Bugsnag.notify(e) do |report|
      report.severity = 'warning'
      report.add_metadata(:read_job, { mp_ids: measurement_point_ids })
    end
  end
end
