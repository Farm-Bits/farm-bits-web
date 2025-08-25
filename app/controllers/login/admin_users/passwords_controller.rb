# frozen_string_literal: true

class Login::AdminUsers::PasswordsController < Devise::PasswordsController
  inertia_share do
    { userScope: 'admin_users' }
  end

  # GET /resource/password/new
  def new
    render inertia: 'Login/Passwords/New'
  end

  # POST /resource/password
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    else
      render inertia: 'Login/Passwords/New', props: {
        errors: resource.errors.full_messages
      }
    end
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  def edit
    self.resource = resource_class.new
    set_minimum_password_length
    resource.reset_password_token = params[:reset_password_token]
    render inertia: 'Login/Passwords/Edit', props: {
      reset_password_token: params[:reset_password_token]
    }
  end

  # PUT /resource/password
  def update
    self.resource = resource_class.reset_password_by_token(resource_params)
    yield resource if block_given?

    if resource.errors.empty?
      resource.unlock_access! if unlockable?(resource)
      if resource_class.sign_in_after_reset_password
        flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
        set_flash_message!(:notice, flash_message)
        resource.after_database_authentication
        sign_in(resource_name, resource)
      else
        set_flash_message!(:notice, :updated_not_active)
      end
      respond_with resource, location: after_resetting_password_path_for(resource)
    else
      set_minimum_password_length
      render inertia: 'Login/Passwords/Edit', props: {
        reset_password_token: params[:admin_user][:reset_password_token],
        errors: resource.errors.full_messages
      }
    end
  end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
