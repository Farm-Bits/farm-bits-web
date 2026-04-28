# Shared enqueueing logic for Modbus reads. Takes a collection of
# MeasurementPoints (already loaded with READ_COORDINATES_INCLUDES),
# groups them by endpoint, and enqueues one ModbusEndpointReadJob per
# endpoint.
#
# Used by ModbusPollingJob (cron), ModbusRefreshJob (on-demand), and any
# other code that needs to trigger reads. Centralizes the per-endpoint
# job-splitting policy so callers don't duplicate it.
#
module ModbusReadEnqueuer
  module_function

  # @param measurement_points [Enumerable<MeasurementPoint>] MPs already
  #   loaded with read_coordinates associations preloaded.
  # @return [Integer] number of jobs enqueued
  def enqueue(measurement_points)
    by_endpoint = measurement_points
      .select { |mp| mp.read_coordinates.present? }
      .group_by { |mp| mp.read_coordinates.endpoint_key }

    by_endpoint.each_value do |group|
      ModbusEndpointReadJob.perform_async(group.map(&:id))
    end

    by_endpoint.size
  end
end
