class Api::RegionsController < ApplicationController
  rate_limit to: 10, within: 3.minutes

  def index
    begin
      regions = fetch_from_geonames(
        path: '/searchJSON',
        params: {
          q: params[:country],
          featureClass: 'A',
          featureCode: 'ADM1',
          maxRows: 1000
        }
      )

      render json: regions
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      render json: { error: 'Request timeout' }, status: :gateway_timeout
    rescue JSON::ParserError => e
      render json: { error: 'Invalid response format' }, status: :bad_gateway
    rescue StandardError => e
      render json: { error: e.message }, status: :service_unavailable
    end
  end

  def cities
    begin
      cities = fetch_from_geonames(
        path: '/searchJSON',
        params: {
          q: params[:country],
          # adminCode1: params[:region],
          featureClass: 'P',
          featureCode: 'PPL',
          maxRows: 1000
        }
      )

      render json: cities
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      render json: { error: 'Request timeout' }, status: :gateway_timeout
    rescue JSON::ParserError => e
      render json: { error: 'Invalid response format' }, status: :bad_gateway
    rescue StandardError => e
      render json: { error: e.message }, status: :service_unavailable
    end
  end

  private
    def fetch_from_geonames(path:, params:)
      params_with_username = params.merge(
        username: Rails.application.credentials[:geonames][:username],
        type: 'json'
      )
      uri = URI::HTTP.build(
        host: 'api.geonames.org',
        path: path,
        query: params_with_username.to_query
      )

      response = Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new(uri)
        http.request(request)
      end

      case response
      when Net::HTTPSuccess
        data = JSON.parse(response.body)
        if data['geonames'].present?
          data['geonames'].sort_by! { |location| location['name'].downcase }
        end
        data
      else
        raise "GeoNames API error: #{response.code} - #{response.message}"
      end
    end
end
