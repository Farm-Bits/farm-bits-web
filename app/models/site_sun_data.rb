class SiteSunData < ApplicationRecord
  belongs_to :site

  # ===========================================
  # Validations
  # ===========================================
  validates :date, presence: true, uniqueness: { scope: :site_id }
  validates :sunrise, presence: true
  validates :sunset, presence: true
  validate :sunrise_before_sunset

  # ===========================================
  # Scopes
  # ===========================================
  scope :for_date, ->(date) { where(date: date) }
  scope :for_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :recent, -> { where(date: 30.days.ago..Date.current) }

  # ===========================================
  # Class Methods
  # ===========================================

  # Find or fetch sun data for a specific site and date
  def self.find_or_fetch_for(site, date)
    find_by(site: site, date: date) || fetch_from_api(site, date)
  end

  # Fetch sun data from external API
  def self.fetch_from_api(site, date)
    return nil unless site.latitude.present? && site.longitude.present?

    # Using sunrise-sunset.org API (free, no key required)
    url = "https://api.sunrise-sunset.org/json?lat=#{site.latitude}&lng=#{site.longitude}&date=#{date.iso8601}&formatted=0"

    response = Net::HTTP.get(URI(url))
    data = JSON.parse(response)

    return nil unless data['status'] == 'OK'

    results = data['results']

    create!(
      site: site,
      date: date,
      sunrise: Time.parse(results['sunrise']),
      sunset: Time.parse(results['sunset']),
      solar_noon: Time.parse(results['solar_noon']),
      civil_twilight_begin: Time.parse(results['civil_twilight_begin']),
      civil_twilight_end: Time.parse(results['civil_twilight_end']),
      day_length_seconds: results['day_length'],
      data_source: 'sunrise-sunset.org',
      fetched_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.error "Failed to fetch sun data for site #{site.id} on #{date}: #{e.message}"
    nil
  end

  # Prefetch sun data for a date range
  def self.prefetch_for_site(site, start_date: Date.current, days: 30)
    dates_to_fetch = (start_date..(start_date + days.days)).to_a
    existing_dates = where(site: site, date: dates_to_fetch).pluck(:date)
    missing_dates = dates_to_fetch - existing_dates

    missing_dates.each do |date|
      fetch_from_api(site, date)
      sleep(0.5) # Rate limiting
    end
  end

  # ===========================================
  # Instance Methods
  # ===========================================
  def to_s
    "#{site.name} - #{date}"
  end

  # Check if a given time falls during day hours
  def is_day?(timestamp)
    time = timestamp.in_time_zone(site.time_zone || 'UTC')
    time >= sunrise && time < sunset
  end

  # Check if a given time falls during night hours
  def is_night?(timestamp)
    !is_day?(timestamp)
  end

  # Day length formatted as hours:minutes
  def day_length_formatted
    return nil unless day_length_seconds

    hours = day_length_seconds / 3600
    minutes = (day_length_seconds % 3600) / 60
    format('%02d:%02d', hours, minutes)
  end

  # Sunrise in site's timezone
  def sunrise_local
    sunrise&.in_time_zone(site.time_zone || 'UTC')
  end

  # Sunset in site's timezone
  def sunset_local
    sunset&.in_time_zone(site.time_zone || 'UTC')
  end

  private

  def sunrise_before_sunset
    return unless sunrise.present? && sunset.present?

    if sunrise >= sunset
      errors.add(:sunrise, 'must be before sunset')
    end
  end
end
