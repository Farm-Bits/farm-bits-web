class UserArea::ApplicationController < ApplicationController
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :ensure_user_has_client_access
  before_action :set_current_client
  before_action :set_current_site
  after_action :verify_pundit_authorization
  inertia_share do
    {
      userScope: 'users',
      user: current_user,
      client: current_client,
      role: current_client_user&.role,
      clients: @clients,
      site: current_site,
      sites: policy_scope(Site),
    }
  end

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected
    def ensure_user_has_client_access
      if current_user.active_clients_connections.empty?
        redirect_to user_client_setup_path
      end
    end

    def set_current_client
      @clients = current_user.active_clients_connections

      if params[:client_id]
        @current_client = @clients.find(params[:client_id])
      elsif session[:current_client_id]
        @current_client = @clients.find_by(id: session[:current_client_id])
      end
      @current_client ||= @clients.first

      @current_client_user = current_user.client_user_for(@current_client)

      session[:current_client_id] = @current_client&.id
    end

    def set_current_site
      context = {
        current_user: current_user,
        current_client: current_client,
        current_client_user: current_client_user,
        current_site: nil
      }
      sites = SitePolicy::Scope.new(context, Site).resolve

      if params[:site_id]
        @current_site = sites.find_by(id: params[:site_id])
      elsif session[:current_site_id]
        @current_site = sites.find_by(id: session[:current_site_id])
      else
        @current_site = sites.first
      end

      session[:current_site_id] = @current_site&.id
    end

    def current_client
      @current_client
    end

    def current_client_user
      @current_client_user
    end

    def current_site
      @current_site
    end

    def pundit_user
      {
        current_user: current_user,
        current_client: current_client,
        current_client_user: current_client_user,
        current_site: current_site
      }
    end

  private
    def verify_pundit_authorization
      if action_name == "index"
        verify_authorized
        verify_policy_scoped
      else
        verify_authorized
      end
    end

    def user_not_authorized
      respond_to do |format|
        format.html { redirect_to root_path, alert: 'You are not authorized to perform this action.' }
        format.json { render json: { error: 'Not authorized' }, status: :forbidden }
      end
    end
end
