module Api
  module V1
    module Hooks
      # Inbound status push from the VPN manager. Low-latency complement to
      # GatewayStatusSyncJob; matched by label, funneled through the same
      # Gateway#apply_status! entry point so transition handling stays in one place.
      class GatewayStatusController < ActionController::API
        before_action :authenticate_hook_secret!

        def update
          gateway = Gateway.find_by(label: params[:label])

          if gateway.nil?
            return render json: { error: 'Unknown gateway' }, status: :not_found
          end

          status = params[:connection_status].to_s

          if !Gateway::CONNECTION_STATUSES.include?(status)
            return render json: { error: "Invalid status: #{status}" }, status: :unprocessable_entity
          end

          gateway.apply_status!(status, status_updated_at: parsed_changed_at)
          render json: { status: 'ok' }
        rescue => e
          Rails.logger.error("[GatewayStatusHook] failed for label #{params[:label]}: #{e.class} - #{e.message}")
          render json: { error: e.message }, status: :unprocessable_entity
        end

        private
          def parsed_changed_at
            raw = params[:status_changed_at]
            if raw.blank?
              return Time.current
            end

            Time.zone.parse(raw.to_s)
          end

          def authenticate_hook_secret!
            expected = ENV['VPN_HOOK_SECRET'].to_s
            provided = request.headers['HTTP_X_HOOK_SECRET'].to_s

            if expected.empty? || !ActiveSupport::SecurityUtils.secure_compare(provided, expected)
              render json: { error: 'Unauthorized' }, status: :unauthorized
            end
          end
      end
    end
  end
end
