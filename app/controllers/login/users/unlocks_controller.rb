# frozen_string_literal: true

class Login::Users::UnlocksController < Devise::UnlocksController
  inertia_share do
    { userScope: 'users' }
  end

  # GET /resource/unlock/new
  def new
    render inertia: 'Login/Unlocks/New'
  end

  # POST /resource/unlock
  def create
    self.resource = resource_class.send_unlock_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_sending_unlock_instructions_path_for(resource))
    else
      render inertia: 'Login/Unlocks/New', props: {
        errors: resource.errors.full_messages
      }
    end
  end

  # GET /resource/unlock?unlock_token=abcdef
  def show
    self.resource = resource_class.unlock_access_by_token(params[:unlock_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message! :notice, :unlocked
      respond_with_navigational(resource){ redirect_to after_unlock_path_for(resource) }
    else
      render inertia: 'Login/Unlocks/New', props: {
        errors: resource.errors.full_messages
      }
    end
  end

  # protected

  # The path used after sending unlock password instructions
  # def after_sending_unlock_instructions_path_for(resource)
  #   super(resource)
  # end

  # The path used after unlocking the resource
  # def after_unlock_path_for(resource)
  #   super(resource)
  # end
end
