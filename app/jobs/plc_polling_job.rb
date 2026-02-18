class PlcPollingJob
  include Sidekiq::Job
  queue_as :default
  sidekiq_options retry: 3

  def perform
    plcs = Plc.joins(:gateway, :measurement_points, site: :company)
      .where(active: true)
      .where(sites: { companies: { active: true } })
      .where(gateways: { active: true })
      .where(measurement_points: { active: true, data_collection_enabled: true })
      .distinct

    plcs.find_each do |plc|
      PlcReadJob.perform_async(plc.id)
    end
  end
end
