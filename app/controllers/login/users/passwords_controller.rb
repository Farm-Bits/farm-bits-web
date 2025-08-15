# frozen_string_literal: true

class Login::Users::PasswordsController < Devise::PasswordsController
  # GET /resource/password/new
  def new
    render inertia: 'Login/Passwords/New', props: {
      userScope: 'users'
    }
  end

  # POST /resource/password
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    else
      render inertia: 'Login/Passwords/New', props: {
        userScope: 'users',
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
      userScope: 'users',
      errors: resource.errors.full_messages
    }
  end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
