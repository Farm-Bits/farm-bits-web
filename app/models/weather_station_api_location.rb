class WeatherStationApiLocation < ApplicationRecord
 audited

  has_many :weather_station_api_raw_values, dependent: :destroy

  has_many :weather_station_api_hourly_aggregations, dependent: :destroy

  validates :name, presence: true
  validates :latitude, presence: true, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, presence: true, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validates :provider, presence: true
  validates :time_zone, presence: true, inclusion: { in: TZInfo::Timezone.all.map(&:identifier) }
  validates :fetch_interval_minutes, presence: true, numericality: { greater_than: 0 }

  scope :needs_fetch, -> {
    where(active: true)
    .where(
      "last_fetched_at IS NULL OR last_fetched_at < DATE_SUB(NOW(), INTERVAL fetch_interval_minutes MINUTE)"
    )
  }

  # Find weather locations within a radius (in km) of given coordinates
  # Uses Haversine approximation suitable for short distances
  def self.nearby(latitude, longitude, radius_km: 10)
    # Approximate degrees per km at given latitude
    lat_delta = radius_km / 111.0
    lng_delta = radius_km / (111.0 * Math.cos(latitude * Math::PI / 180.0))

    where(
      "latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?",
      latitude - lat_delta, latitude + lat_delta,
      longitude - lng_delta, longitude + lng_delta
    )
  end

  def provider_adapter
    case provider
    when 'ims'
      WeatherStationApiProviders::Ims::ImsProvider.new(self)
    else
      raise "Unknown weather provider: #{provider}"
    end
  end

  def weather_station_api_metric_keys
    if !active?
      return []
    end

    channel_map = provider_adapter.class::CHANNEL_MAP
    provider_config['active_channels'].map { |channel_name| channel_map[channel_name] }.compact
  end
end
