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

      response = self.class.get('/place/textsearch/json', {
        query: {
          input: city_name,
          type: 'city',
          components: "country:#{country_code}",
          key: @api_key
        }
      })

      if response.success? && response['status'] == 'OK'
        return response['results'].any? { |result| result['name'] == city_name }
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
          input: country_name,
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
end
