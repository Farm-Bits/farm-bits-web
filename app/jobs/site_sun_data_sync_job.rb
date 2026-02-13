class SiteSunDataSyncJob
  include Sidekiq::Job
  queue_as :low

  def perform(site_id = nil)
    if site_id
      site = Site.find(site_id)
      SiteSunDataSyncService.sync(site: site, from: Date.current, to: Date.current + 7.days)
    else
      SiteSunDataSyncService.sync_all(from: Date.current, to: Date.current + 7.days)
    end
  end
end
