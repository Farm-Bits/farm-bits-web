class UserArea::ClientSetupController < UserArea::ApplicationController
  skip_before_action :ensure_user_has_client_access

  def new
    errors = current_user.active_clients_connections.any? ? nil : ['You do not have access to any company. Create one now.']
    render inertia: 'UserArea/ClientSetup', props: {
      errors: errors
    }
  end

  def create
    @client = Client.new(client_params)
    @client.client_users_attributes = [{ user: current_user, role: RoleManageable.highest_role }]

    if @client.save
      session[:current_client_id] = @client.id
      redirect_to root_path, notice: 'Company created successfully!'
    else
      render inertia: 'UserArea/ClientSetup', props: {
        errors: @client.errors.full_messages
      }
    end
  end

  protected
    def ensure_user_has_no_client_access
      if current_user.active_clients_connections.any?
        redirect_to root_path
      end
    end

  private
    def client_params
      params.require(:client).permit(:name, site_attributes: [:country, :city, :latitude, :longitude, :altitude])
    end
end
