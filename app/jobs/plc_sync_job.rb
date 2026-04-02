class PlcSyncJob
  include Sidekiq::Job
  sidekiq_options queue: 'critical'

  def perform
    Plc.operational.find_each do |plc|
      PlcClockWriteJob.perform_async(plc.id)
      SunDataPlcWriteJob.perform_async(plc.id)
      IoActiveSyncJob.perform_async(plc.id)
      OperationModeSyncJob.perform_async(plc.id)
    end
  end
end
