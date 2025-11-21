class UserArea::ApplicationController < ApplicationController
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :ensure_user_has_client_access
  before_action :set_current_client
  after_action :verify_pundit_authorization
  inertia_share do
    {
      userScope: 'users',
      user: current_user,
      currentClient: @current_client,
      clients: @clients,
      sites: policy_scope(Site)
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
      @clients = policy_scope(Client)

      if params[:client_id]
        @current_client = @clients.find(params[:client_id])
      elsif session[:current_client_id]
        @current_client = @clients.find_by(id: session[:current_client_id])
      end
      @current_client ||= @clients.first

      session[:current_client_id] = @current_client&.id

      current_user.instance_variable_set(:@current_client, @current_client)
    end

    def current_client
      @current_client
    end

    def policy_scope(scope, policy_scope_class: nil)
      models_with_custom_scope = [Invitation, Site, User]
      if models_with_custom_scope.include?(scope) || (scope.respond_to?(:model) && models_with_custom_scope.include?(scope.model))
        model_class = scope.respond_to?(:model) ? scope.model : scope
        policy_scope_class ||= "#{model_class.name}Policy::Scope".constantize
        policy_scope_class.new(current_user, scope, current_client: current_client).resolve
      else
        super
      end
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
