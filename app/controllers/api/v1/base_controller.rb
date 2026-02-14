module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_token!

      private
        def authenticate_api_token!
          token = request.headers['Authorization']&.remove('Bearer ')

          if !token.present? || !ActiveSupport::SecurityUtils.secure_compare(token, Rails.application.credentials[:plc_ingestion][:ingestion_client_api_key])
            render json: { error: 'Unauthorized' }, status: :unauthorized
          end
        end
    end
  end
end
