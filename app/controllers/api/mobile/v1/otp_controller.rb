class Api::Mobile::V1::OtpController < Api::Mobile::V1::BaseController
  skip_before_action :authenticate_mobile_request!, only: [:verify, :resend]
  skip_before_action :touch_user_session, only: [:verify, :resend]
  skip_before_action :ensure_user_has_company_access!, only: [:verify, :resend]
  skip_before_action :resolve_company_and_site_from_url, only: [:verify, :resend]

  # POST /api/mobile/v1/otp/verify
  def verify
    user_session = locate_pending_session
    if user_session.nil?
      return render json: { error: 'invalid_session' }, status: :unauthorized
    end

    case user_session.verify_otp!(params[:code])
    when :ok
      @current_user_session = user_session
      @current_user = user_session.authenticatable
      render json: authenticated_payload(user_session, user_session.mobile_token), status: :ok
    when :invalid
      render json: { error: 'invalid_code' }, status: :unauthorized
    when :expired
      if !user_session.issue_otp!
        user_session.revoke!
        render json: { error: 'code_expired_send_failed' }, status: :service_unavailable
        return
      end
      render json: { error: 'code_expired', session_id: user_session.id }, status: :unauthorized
    when :too_many_attempts
      render json: { error: 'too_many_attempts' }, status: :unauthorized
    end
  end

  # POST /api/mobile/v1/otp/resend
  def resend
    user_session = locate_pending_session
    if user_session.nil?
      return render json: { error: 'invalid_session' }, status: :unauthorized
    end

    if !user_session.issue_otp!
      render json: { error: 'send_failed' }, status: :service_unavailable
      return
    end

    render json: { ok: true }
  end

  private
    def locate_pending_session
      session_id = params[:session_id]
      if session_id.blank?
        return nil
      end

      session = UserSession.active.find_by(id: session_id)
      if session.nil? || session.mfa_verified_at.present?
        return nil
      end

      session
    end
end
