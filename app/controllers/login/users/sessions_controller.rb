# frozen_string_literal: true

class Login::Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]
  inertia_share do
    { userScope: 'users' }
  end

  # GET /resource/sign_in
  def new
    render inertia: 'Login/Sessions/New'
  end

  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate(auth_options)

    if resource.nil?
      render inertia: 'Login/Sessions/New', props: {
        errors: ['Invalid email or password.']
      }
      return
    end

    user_session, remember_token = UserSession.create_web!(
      authenticatable: resource,
      request:         request,
      remembered:      remember_me_param?
    )

    if user_session.requires_otp?
      if !user_session.issue_otp!
        user_session.revoke!
        render inertia: 'Login/Sessions/New', props: {
          errors: ['Could not send sign-in code. Please try again in a moment.']
        }
        return
      end

      request.session["#{resource_name}_pending_session_id"] = user_session.id
      redirect_to otp_challenge_path
      return
    end

    finalize_sign_in!(user_session, remember_token)
  end

  # DELETE /resource/sign_out
  def destroy
    user_session = current_user_session

    if user_session.nil?
      session_id = request.session["#{resource_name}_session_id"]
      if session_id
        user_session = UserSession.find_by(id: session_id)
      end
    end

    if user_session.present?
      user_session.revoke!
    end

    request.session.delete("#{resource_name}_session_id")
    request.session.delete("#{resource_name}_pending_session_id")
    cookies.delete("#{resource_name}_remember")
    super
  end

  # GET /resource/otp - the challenge page itself.
  def otp_challenge
    user_session = pending_user_session
    if user_session.nil?
      redirect_to new_session_path(resource_name),
        alert: 'No sign-in in progress. Please sign in again.'
      return
    end

    render inertia: 'Login/Sessions/VerifyOtp', props: {
      otp_destination: user_session.authenticatable.email
    }
  end

  # POST /resource/otp/verify
  def verify_otp
    user_session = pending_user_session
    if user_session.nil?
      redirect_to new_session_path(resource_name),
        alert: 'Sign-in expired. Please sign in again.'
      return
    end

    case user_session.verify_otp!(params[:otp])
    when :ok
      self.resource = user_session.authenticatable
      request.session.delete("#{resource_name}_pending_session_id")
      request.session["#{resource_name}_session_id"] = user_session.id
      request.env["user_session.current.#{resource_name}"] = user_session
      sign_in(resource_name, resource)
      redirect_to after_sign_in_path_for(resource)
    when :invalid
      redirect_to otp_challenge_path,
        inertia: { errors: { otp: 'Incorrect code. Please try again.' } }
    when :expired
      if !user_session.issue_otp!
        request.session.delete("#{resource_name}_pending_session_id")
        user_session.revoke!
        redirect_to new_session_path(resource_name),
          alert: 'Code expired and we could not send a new one. Please sign in again.'
        return
      end
      redirect_to otp_challenge_path,
        inertia: { errors: { otp: 'Code expired. We sent you a new one.' } }
    when :too_many_attempts
      request.session.delete("#{resource_name}_pending_session_id")
      user_session.revoke!
      redirect_to new_session_path(resource_name),
        alert: 'Too many incorrect codes. Please sign in again.'
    end
  end

  # POST /resource/otp/resend
  def resend_otp
    user_session = pending_user_session
    if user_session.nil?
      redirect_to new_session_path(resource_name),
        alert: 'Sign-in expired. Please sign in again.'
      return
    end

    if !user_session.issue_otp!
      redirect_to otp_challenge_path,
        alert: 'Could not send a new code. Please try again in a moment.'
      return
    end

    redirect_to otp_challenge_path, notice: 'A new code has been sent.'
  end

  private
    def finalize_sign_in!(user_session, remember_token)
      set_flash_message!(:notice, :signed_in)

      request.session["#{resource_name}_session_id"] = user_session.id
      request.env["user_session.current.#{resource_name}"] = user_session

      sign_in(resource_name, resource)

      if remember_token.present?
        cookies.signed["#{resource_name}_remember"] = {
          value:     [user_session.id, remember_token],
          expires:   user_session.expires_at,
          httponly:  true,
          secure:    Rails.env.production?,
          same_site: :lax
        }
      end

      respond_with resource, location: after_sign_in_path_for(resource)
    end

    def pending_user_session
      pending_id = request.session["#{resource_name}_pending_session_id"]
      if pending_id.blank?
        return nil
      end

      session = UserSession.find_by(id: pending_id)
      if session.nil? || !session.active?
        request.session.delete("#{resource_name}_pending_session_id")
        return nil
      end

      session
    end

    def current_user_session
      request.env["user_session.current.#{resource_name}"]
    end

    def otp_challenge_path
      "/#{resource_name.to_s.pluralize}/otp"
    end

    def remember_me_param?
      ActiveModel::Type::Boolean.new.cast(params.dig(resource_name, :remember_me))
    end
end
