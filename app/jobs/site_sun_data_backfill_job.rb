class SiteSunDataBackfillJob
  include Sidekiq::Job
  queue_as :low

  def perform(site_id, from_date, to_date)
    site = Site.find(site_id)
    from = Date.parse(from_date)
    to = Date.parse(to_date)

    SiteSunDataSyncService.sync(site: site, from: from, to: to)
  end
end
