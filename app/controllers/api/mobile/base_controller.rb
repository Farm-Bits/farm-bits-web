class Api::Mobile::BaseController < ActionController::API

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from MobileJwt::ExpiredError, with: :render_token_expired
  rescue_from MobileJwt::DecodeError, with: :render_unauthorized

  before_action :authenticate_mobile_request!
  before_action :touch_user_session

  attr_reader :current_user, :current_user_session

  private
    def authenticate_mobile_request!
      payload = MobileJwt.decode(bearer_token)

      user_session_id = payload[:session_id]
      jti             = payload[:jti]
      if user_session_id.blank? || jti.blank?
        return render_unauthorized
      end

      session = UserSession.active.find_by(id: user_session_id)
      if session.nil?
        return render_unauthorized
      end

      if !ActiveSupport::SecurityUtils.secure_compare(session.jti.to_s, jti.to_s)
        return render_unauthorized
      end

      if !session.fully_authorized?
        return render_token_otp_required(session)
      end

      authenticatable = session.authenticatable
      if authenticatable.nil? ||
        (authenticatable.respond_to?(:active?) && !authenticatable.active?)
        return render_unauthorized
      end

      @current_user_session = session
      @current_user = authenticatable
    end

    def touch_user_session
      if @current_user_session.nil?
        return
      end

      @current_user_session.touch_seen!(
        ip:         request.remote_ip,
        user_agent: request.user_agent
      )
    end

    def bearer_token
      header = request.headers['Authorization'].to_s
      header.start_with?('Bearer ') ? header.delete_prefix('Bearer ') : nil
    end

    def render_unauthorized(_exception = nil)
      render json: { error: 'unauthorized' }, status: :unauthorized
    end

    def render_token_expired(_exception = nil)
      render json: { error: 'token_expired' }, status: :unauthorized
    end

    def render_token_otp_required(session)
      render json: {
        error: 'otp_required',
        session_id: session.id
      }, status: :unauthorized
    end

    def render_not_found(_exception = nil)
      render json: { error: 'not_found' }, status: :not_found
    end

    def render_bad_request(exception)
      render json: { error: 'bad_request', detail: exception.message }, status: :bad_request
    end
end
