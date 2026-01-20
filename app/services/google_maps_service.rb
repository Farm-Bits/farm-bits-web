class GoogleMapsService
  include HTTParty
  base_uri 'https://maps.googleapis.com/maps/api'

  def initialize
    @api_key = Rails.application.credentials[:google][:places_api_key]
  end

  def valid_country?(country_name)
    if country_name.blank?
      return false
    end

    begin
      response = self.class.get('/place/textsearch/json', {
        query: {
          query: country_name,
          type: 'country',
          key: @api_key
        }
      })

      if response.success? && response['status'] == 'OK'
        return response['results'].any? { |result| result['name'] == country_name }
      end

      return false
    rescue => e
      Rails.logger.error("Error validating country: #{e.message}")
      return false
    end
  end

  def valid_city?(city_name, country_name)
    if city_name.blank? || country_name.blank?
      return false
    end

    begin
      country_code = country_code_for(country_name)
      if !country_code
        return false
      end

      search_query = "#{city_name}, #{country_name}"
      response = self.class.get('/place/textsearch/json', {
        query: {
          query: search_query,
          type: 'locality',
          key: @api_key
        }
      })

      if response.success? && response['status'] == 'OK'
        return response['results'].any? do |result|
          city_matches = result['name'].downcase == city_name.downcase

          country_matches = false
          if result['place_id']
            country_matches = city_in_country?(result['place_id'], country_code)
          end

          city_matches && country_matches
        end
      end

      return false
    rescue => e
      Rails.logger.error("Error validating city: #{e.message}")
      return false
    end
  end

  def country_code_for(country_name)
    begin
      response = self.class.get('/place/textsearch/json', {
        query: {
          query: country_name,
          type: 'country',
          key: @api_key
        }
      })

      if response.success? && response['status'] == 'OK' && response['results'].any?
        place_id = response['results'].first['place_id']

        details_response = self.class.get('/place/details/json', {
          query: {
            place_id: place_id,
            fields: 'address_components',
            key: @api_key
          }
        })

        if details_response.success? && details_response['status'] == 'OK'
          country_component = details_response['result']['address_components'].find do |component|
            component['types'].include?('country')
          end

          return country_component['short_name'] if country_component
        end
      end

      return nil
    rescue => e
      Rails.logger.error("Error getting country code: #{e.message}")
      return nil
    end
  end

  def geocode_country(country)
    if !country.present?
      return nil
    end

    response = self.class.get('/geocode/json',
      query: {
        address: country,
        key: @api_key
      }
    )

    if response.success? && response['status'] == 'OK' && response['results'].any?
      location = response['results'].first['geometry']['location']
      {
        latitude: location['lat'],
        longitude: location['lng']
      }
    else
      nil
    end
  rescue => e
    Rails.logger.error("Error geocoding country: #{e.message}")
    nil
  end

  def time_zone_for_coordinates(latitude, longitude, timestamp = Time.current.to_i)
    if !latitude.present? || !longitude.present?
      return nil
    end

    response = self.class.get('/timezone/json',
      query: {
        location: "#{latitude},#{longitude}",
        timestamp: timestamp,
        key: @api_key
      }
    )

    if response.success? && response['status'] == 'OK'
      response['timeZoneId']
    else
      Rails.logger.warn("Google Maps Time Zone API error: #{response['status']} - #{response['errorMessage']}")
      nil
    end
  rescue => e
    Rails.logger.error("Error fetching time zone: #{e.message}")
    nil
  end

  private
    def city_in_country?(place_id, country_code)
      details_response = self.class.get('/place/details/json', {
        query: {
          place_id: place_id,
          fields: 'address_components',
          key: @api_key
        }
      })

      if details_response.success? && details_response['status'] == 'OK'
        address_components = details_response['result']['address_components']
        country_component = address_components.find { |c| c['types'].include?('country') }

        return country_component && country_component['short_name'] == country_code
      end

      return false
    rescue => e
      Rails.logger.error("Error checking if city is in country: #{e.message}")
      return false
    end
end
