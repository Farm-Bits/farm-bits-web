# frozen_string_literal: true

class Login::AdminUsers::ConfirmationsController < Devise::ConfirmationsController
  # GET /resource/confirmation/new
  def new
    render inertia: 'Login/Confirmations/New', props: {
      userScope: 'admin_users'
    }
  end

  # POST /resource/confirmation
  def create
    self.resource = resource_class.send_confirmation_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_resending_confirmation_instructions_path_for(resource_name))
    else
      redirect_back(
        fallback_location: new_confirmation_path(resource_name),
        flash: { errors: resource.errors.full_messages }
      )
    end
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      sign_in(resource_name, resource)
      set_flash_message!(:notice, :confirmed)
      respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
    else
      redirect_back(
        fallback_location: new_confirmation_path(resource_name),
        flash: { errors: resource.errors.full_messages }
      )
    end
  end

  protected

  # The path used after resending confirmation instructions.
  # def after_resending_confirmation_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

    # The path used after confirmation.
    def after_confirmation_path_for(resource_name, resource)
      root_path
    end
end
