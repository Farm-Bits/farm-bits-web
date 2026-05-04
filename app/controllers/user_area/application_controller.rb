class UserArea::ApplicationController < ApplicationController
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :touch_user_session
  before_action :ensure_user_has_company_access
  before_action :set_current_company
  before_action :set_current_site
  after_action :verify_pundit_authorization
  inertia_share do
    {
      userScope: 'users',
      currentUser: current_user,
      currentCompany: current_company,
      currentRole: current_company_user&.role,
      accessibleCompanies: @companies,
      currentSite: current_site ? SiteSerializer.render_as_json(current_site, view: :with_segments) : nil,
      accessibleSites: SiteSerializer.render_as_json(policy_scope(Site)),
      openAlertCount: policy_scope(Alert).open.count
    }
  end

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  protected
    def current_user_session
      request.env['user_session.current.user']
    end

    def touch_user_session
      session = current_user_session
      if session.nil?
        return
      end

      session.touch_seen!(ip: request.remote_ip, user_agent: request.user_agent)
    end

    def ensure_user_has_company_access
      if current_user.active_companies_connections.empty?
        redirect_to user_company_setup_new_path
      end
    end

    def set_current_company
      @companies = current_user.active_companies_connections

      if params[:company_id]
        @current_company = @companies.find_by(id: params[:company_id])
        if !@current_company
          flash[:alert] = "You don't have access to that company."
          redirect_to root_path
          return
        end
      elsif current_user_session&.current_company_id
        @current_company = @companies.find_by(id: current_user_session.current_company_id)
      end

      @current_company ||= @companies.first
      @current_company_user = current_user.company_user_for(@current_company)

      if current_user_session.present? &&
        current_user_session.current_company_id != @current_company&.id
        current_user_session.update_column(:current_company_id, @current_company&.id)
      end
    end

    def set_current_site
      context = {
        current_user: current_user,
        current_company: current_company,
        current_company_user: current_company_user,
        current_site: nil
      }
      sites = SitePolicy::Scope.new(context, Site).resolve

      if params[:site_id]
        @current_site = sites.find_by(id: params[:site_id])
        if !@current_site
          flash[:alert] = "You don't have access to that site."
          redirect_to root_path
          return
        end
      elsif session[:current_site_id]
        @current_site = sites.find_by(id: session[:current_site_id])
      end

      @current_site ||= sites.first
      session[:current_site_id] = @current_site&.id
    end

    def current_company
      @current_company
    end

    def current_company_user
      @current_company_user
    end

    def current_site
      @current_site
    end

    def pundit_user
      {
        current_user: current_user,
        current_company: current_company,
        current_company_user: current_company_user,
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

    def record_not_found(exception)
      respond_to do |format|
        format.html { redirect_to root_path, alert: "That record doesn't exist or you don't have access to it." }
        format.json { render json: { error: 'Record not found' }, status: :forbidden }
      end
    end
end
