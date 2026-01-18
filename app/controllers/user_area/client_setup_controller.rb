class UserArea::ClientSetupController < UserArea::ApplicationController
  skip_before_action :ensure_user_has_client_access, only: [:new, :create]

  def new
    authorize Client, :new?

    errors = current_user.active_clients_connections.empty? ? nil : ['You do not have access to any company. Create one now.']
    render inertia: 'UserArea/ClientSetupForm', props: {
      errors: errors
    }
  end

  def edit
    authorize current_client, :edit?

    @segments = policy_scope(Segment)
    @site_users = policy_scope(SiteUser)
    render inertia: 'UserArea/Settings/index', props: {
      segments: SegmentSerializer.render_as_json(@segments),
      siteUsers: SiteUserSerializer.render_as_json(@site_users)
    }
  end

  def create
    authorize Client, :create?

    client = Client.new(client_params)
    client.client_users_attributes = [{ user: current_user, role: Roleable::ROLE_IDS[:admin] }]

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
    authorize current_client, :update?

    if current_client.update(client_params)
      redirect_to user_client_setup_edit_path
    else
      render inertia: 'UserArea/Settings/index', props: {
        errors: current_client.errors.full_messages
      }
    end
  end

  def destroy
    authorize current_client, :destroy?

    begin
      current_client.destroy!
      redirect_to root_path
    rescue => e
      render inertia: 'UserArea/Settings/index', props: {
        errors: [e.message]
      }
    end
  end

  private
    def client_params
      params.require(:client).permit(:name, :color, site_attributes: [:country, :city, :latitude, :longitude, :altitude])
    end
end
