class UserArea::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_user_has_client_access
  before_action :set_current_client
  inertia_share do
    {
      userScope: 'users',
      user: current_user,
      client: current_client,
      clients: current_user.active_clients_connections,
      sites: current_user.accessible_sites_for_client(current_client)
    }
  end

  protected
    def ensure_user_has_client_access
      if current_user.active_clients_connections.empty?
        redirect_to user_client_setup_path
      end
    end

    def ensure_can_manage_users!
      if !current_client.role_for(current_user).can_manage_users?
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end

    helper_method :ensure_can_manage_users!

    def set_current_client
      if params[:client_id]
        @current_client = current_user.active_clients_connections.find(params[:client_id])
      elsif session[:current_client_id]
        @current_client = current_user.active_clients_connections.find_by(id: session[:current_client_id])
      end
      @current_client ||= current_user.active_clients_connections.first

      session[:current_client_id] = @current_client&.id
    end

    def current_client
      @current_client
    end

    helper_method :current_client
end
