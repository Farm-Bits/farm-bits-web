# frozen_string_literal: true

class Login::AdminUsers::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]
  inertia_share do
    { userScope: 'admin_users' }
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

    set_flash_message!(:notice, :signed_in)

    user_session, remember_token = UserSession.create_web!(
      authenticatable: resource,
      request:         request,
      remembered:      remember_me_param?
    )

    request.session["#{resource_name}_session_id"] = user_session.id
    request.env["user_session.current.#{resource_name}"] = user_session

    sign_in(resource_name, resource)

    if remember_token.present?
      cookies.signed["#{resource_name}_remember"] = {
        value:    [user_session.id, remember_token],
        expires:  user_session.expires_at,
        httponly: true,
        secure:   Rails.env.production?,
        same_site: :lax
      }
    end

    respond_with resource, location: after_sign_in_path_for(resource)
  end

  # DELETE /resource/sign_out
  def destroy
    user_session = request.env["user_session.current.#{resource_name}"]

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
    cookies.delete("#{resource_name}_remember")
    super
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  private
    def remember_me_param?
      ActiveModel::Type::Boolean.new.cast(params.dig(resource_name, :remember_me))
    end
end
