class PlcPollingJob
  include Sidekiq::Job
  sidekiq_options queue: 'default'

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
