# frozen_string_literal: true

class Login::Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  def new
    render inertia: 'Login/Sessions/New', props: {
      userScope: 'users'
    }
  end

  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate(auth_options)

    if resource&.persisted?
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      redirect_back(
        fallback_location: new_session_path(resource_name),
        alert: 'Invalid email or password.'
      )
    end
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
