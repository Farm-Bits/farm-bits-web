class Api::Mobile::V1::SessionsController < Api::Mobile::V1::BaseController
  skip_before_action :authenticate_mobile_request!, only: [:create]
  skip_before_action :touch_user_session,           only: [:create]

  # POST /api/mobile/v1/sign_in
  def create
    user = authenticate_credentials
    if user.nil?
      render json: { error: 'invalid_credentials' }, status: :unauthorized
      return
    end

    user_session, token = UserSession.create_mobile!(
      authenticatable: user,
      request:         request,
      client_name:     params[:client_name]
    )

    if user_session.requires_otp?
      render json: {
        token:      token,
        otp_required: true,
        session_id: user_session.id
      }, status: :ok
      return
    end

    render json: {
      token:   token,
      session: UserSessionSerializer.render_as_json(
        user_session,
        current_session_id: user_session.id
      )
    }, status: :created
  end

  # DELETE /api/mobile/v1/sign_out
  def destroy_current
    current_user_session.revoke!
    render json: { ok: true }, status: :ok
  end

  # GET /api/mobile/v1/sessions
  def index
    sessions = current_user.user_sessions.active.order(last_seen_at: :desc)

    render json: {
      sessions: UserSessionSerializer.render_as_json(
        sessions,
        current_session_id: current_user_session.id
      )
    }
  end

  # DELETE /api/mobile/v1/sessions/:id
  def destroy
    user_session = current_user.user_sessions.active.find(params[:id])
    user_session.revoke!

    render json: { ok: true, revoked_self: user_session.id == current_user_session.id }
  end

  private
    def authenticate_credentials
      email    = params[:email].to_s.downcase.strip
      password = params[:password].to_s
      scope    = params[:scope].to_s

      if email.blank? || password.blank?
        return nil
      end

      authenticatable_class = scope_to_class(scope)
      if authenticatable_class.nil?
        return nil
      end

      user = authenticatable_class.find_by(email: email)
      if user.nil? || !user.valid_password?(password)
        return nil
      end

      if user.respond_to?(:active_for_authentication?) && !user.active_for_authentication?
        return nil
      end

      user
    end

    def scope_to_class(scope)
      case scope
      when 'user', '', nil then User
      when 'admin_user'    then AdminUser
      else nil
      end
    end
end
