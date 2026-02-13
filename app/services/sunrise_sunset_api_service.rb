class SunriseSunsetApiService
  include HTTParty
  base_uri 'https://api.sunrise-sunset.org'

  class ApiError < StandardError; end

  def self.fetch(site:, date:)
    new(site).fetch(date)
  end

  def self.fetch_range(site:, from:, to:)
    new(site).fetch_range(from, to)
  end

  def initialize(site)
    @site = site
    @latitude, @longitude = resolve_coordinates
    if !@latitude || !@longitude
      raise ArgumentError, "Could not determine coordinates for site #{@site.id}"
    end
  end

  def fetch(date)
    response = self.class.get('/json', query: {
      lat: @latitude,
      lng: @longitude,
      date: date.to_s,
      formatted: 0,
      tzid: @site.time_zone
    }, timeout: 10)

    if !response.success?
      raise ApiError, "HTTP #{response.code} for site #{@site.id} on #{date}"
    end

    data = response.parsed_response

    if data['status'] != 'OK'
      raise ApiError, "API status: #{data['status']} for site #{@site.id} on #{date}"
    end

    parse_results(data['results'], date)
  end

  def fetch_range(from, to)
    (from..to).map do |date|
      fetch(date).tap { sleep(0.2) }
    end
  end

  private
    def resolve_coordinates
      if @site.latitude.present? && @site.longitude.present?
        return [@site.latitude, @site.longitude]
      end

      if @site.geocoded_latitude.present? && @site.geocoded_longitude.present?
        return [@site.geocoded_latitude, @site.geocoded_longitude]
      end

      coords, source = geocode_site
      if coords
        @site.update_columns(
          geocoded_latitude: coords[:latitude],
          geocoded_longitude: coords[:longitude]
        )
        return [coords[:latitude], coords[:longitude]]
      end

      [nil, nil]
    end

    def geocode_site
      service = GoogleMapsService.new

      if @site.city.present? && @site.country.present?
        source = "#{@site.city}, #{@site.country}"
        coords = service.geocode_country(source)
        if coords
          return [coords, source]
        end
      end

      if @site.country.present?
        coords = service.geocode_country(@site.country)
        if coords
          return [coords, @site.country]
        end
      end

      [nil, nil]
    end

    def parse_results(results, date)
      sunrise_time = Time.parse(results['sunrise'])
      sunset_time = Time.parse(results['sunset'])

      # Polar edge case: API returns epoch when there's no sunrise/sunset
      if sunrise_time.year == 1970 || sunset_time.year == 1970
        Rails.logger.warn("[SunData] Polar edge case for site #{@site.id} on #{date}")
        if results['day_length'].to_i == 0
          sunrise_time = sunset_time = Time.parse('12:00:00')
        else
          sunrise_time = Time.parse('00:00:00')
          sunset_time = Time.parse('23:59:59')
        end
      end

      civil_begin = safe_parse_time(results['civil_twilight_begin'])
      civil_end = safe_parse_time(results['civil_twilight_end'])

      {
        date: date,
        sunrise: sunrise_time.strftime('%H:%M:%S'),
        sunset: sunset_time.strftime('%H:%M:%S'),
        civil_twilight_begin: civil_begin&.strftime('%H:%M:%S'),
        civil_twilight_end: civil_end&.strftime('%H:%M:%S'),
        day_length_seconds: results['day_length']&.to_i
      }
    end

    def safe_parse_time(value)
      begin
        if value.blank?
          return nil
        end

        parsed = Time.parse(value)
        parsed.year == 1970 ? nil : parsed
      rescue ArgumentError
        nil
      end
    end
end
