class SiteSunDataSyncService
  class SyncError < StandardError; end

  def self.sync(site:, from: Date.current, to: Date.current + 7.days)
    new(site).sync(from, to)
  end

  def self.sync_all(from: Date.current, to: Date.current + 7.days)
    results = { synced: 0, skipped: 0, failed: 0 }

    Site.find_each do |site|
      count = sync(site: site, from: from, to: to)
      if count
        results[:synced] += 1
      else
        results[:skipped] += 1
      end
    rescue SunriseSunsetClient::ApiError, SyncError => e
      results[:failed] += 1
      Rails.logger.error("[SiteSunDataSync] Failed for site #{site.id} (#{site.name}): #{e.message}")
    end

    results
  end

  def initialize(site)
    @site = site
  end

  def sync(from, to)
    if !can_resolve_coordinates?
      return nil
    end

    missing_dates = find_missing_dates(from, to)
    if missing_dates.empty?
      return 0
    end

    api = SunriseSunsetClient.new(@site)
    records = []

    missing_dates.each do |date|
      begin
        data = api.fetch(date)
        records << data.merge(site_id: @site.id, created_at: Time.current, updated_at: Time.current)
        sleep(0.2)
      rescue SunriseSunsetClient::ApiError => e
        Rails.logger.error("[SiteSunDataSync] Failed for site #{@site.id} on #{date}: #{e.message}")
      end
    end

    if records.any?
      SiteSunData.insert_all(records)
    end

    records.size
  end

  private
    def can_resolve_coordinates?
      if @site.latitude.present? && @site.longitude.present?
        return true
      end

      if @site.geocoded_latitude.present? && @site.geocoded_longitude.present?
        return true
      end

      if @site.country.present?
        return true
      end

      Rails.logger.info("[SiteSunDataSync] Skipping site #{@site.id} (#{@site.name}): no coordinates and no country")
      false
    end

    def find_missing_dates(from, to)
      existing_dates = @site.site_sun_data
        .where(date: from..to)
        .pluck(:date)
        .to_set

      (from..to).reject { |d| existing_dates.include?(d) }
    end
end
