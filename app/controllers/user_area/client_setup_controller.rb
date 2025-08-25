class UserArea::ClientSetupController < UserArea::ApplicationController
  skip_before_action :ensure_user_has_client_access

  def new
    errors = current_user.active_clients_connections.any? ? nil : ['You do not have access to any company. Create one now.']
    render inertia: 'UserArea/ClientSetupForm', props: {
      errors: errors
    }
  end

  def edit
    if current_client.role_for(current_user).can_manage_client_settings?
      render inertia: 'UserArea/Settings/index'
    else
      redirect_to root_path, alert: 'You do not have permission to edit this company.'
    end
  end

  def create
    client = Client.new(client_params)
    client.client_users_attributes = [{ user: current_user, role: RoleManageable.highest_role }]

    if client.save
      session[:current_client_id] = client.id
      redirect_to root_path
    else
      render inertia: 'UserArea/ClientSetupForm', props: {
        errors: client.errors.full_messages
      }
    end
  end

  def update
    if current_client.role_for(current_user).can_manage_client_settings?
      if current_client.update(client_params)
        redirect_to user_client_setup_edit_path
      else
        render inertia: 'UserArea/Settings/index', props: {
          errors: current_client.errors.full_messages
        }
      end
    else
      redirect_to root_path, alert: 'You do not have permission to edit this company.'
    end
  end

  def destroy
    if current_client.role_for(current_user).can_manage_client_settings?
      current_client.destroy
      redirect_to root_path
    else
      redirect_to root_path, alert: 'You do not have permission to edit this company.'
    end
  end

  private
    def client_params
      params.require(:client).permit(:name, :color, site_attributes: [:country, :city, :latitude, :longitude, :altitude])
    end
end
