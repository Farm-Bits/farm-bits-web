# Cron-driven scheduler. Finds every active MeasurementPoint due for polling
# and enqueues per-endpoint read jobs via ModbusReadEnqueuer.
#
# This is the only job that applies the needs_polling? filter - other
# callers (refresh, initial read) bypass it intentionally to force a read.
#
class ModbusPollingJob
  include Sidekiq::Job
  sidekiq_options queue: 'default', retry: false

  def perform
    mps = MeasurementPoint
      .operational
      .where(data_collection_enabled: true)
      .due_for_polling
      .includes(*MeasurementPoint::READ_COORDINATES_INCLUDES)

    ModbusReadEnqueuer.enqueue(mps)
  end
end
