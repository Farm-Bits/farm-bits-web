class UserArea::ApplicationController < ApplicationController
  include Pundit::Authorization
  include ResolvesUserContext

  before_action :authenticate_user!
  before_action :touch_user_session
  before_action :ensure_user_has_company_access
  before_action :resolve_company_and_site
  after_action  :verify_pundit

  inertia_share do
    {
      userScope: 'users',
      currentController: controller_name,
      currentAction: action_name,
      currentUser: current_user,
      currentCompany: current_company,
      currentRole: current_company_user&.role,
      accessibleCompanies: @companies,
      currentSite: current_site ? SiteSerializer.render_as_json(current_site, view: :with_segments) : nil,
      accessibleSites: SiteSerializer.render_as_json(policy_scope(Site)),
      openAlertCount: current_site ? policy_scope(Alert).open.count : 0
    }
  end

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  protected
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

    def resolve_from_site
      site    = Site.includes(:company).find_by(id: params[:site_id])
      company = @companies.find_by(id: site&.company_id)

      if company.nil?
        return reject_context("You don't have access to that site.")
      end

      if !site_scope_for(company).exists?(id: site.id)
        return reject_context("You don't have access to that site.")
      end

      @current_company      = company
      @current_company_user = current_user.company_user_for(company)
      @current_site         = site
    end

    def resolve_from_company
      @current_company = @companies.find_by(id: params[:company_id])

      if @current_company.nil?
        return reject_context("You don't have access to that company.")
      end

      @current_company_user = current_user.company_user_for(@current_company)
      @current_site         = resolve_site_for(@current_company)
    end

    def resolve_from_session_defaults
      @current_company      = resolve_company
      @current_company_user = current_user.company_user_for(@current_company)
      @current_site         = resolve_site_for(@current_company)
    end

    def resolve_company_and_site
      @companies = current_user.active_companies_connections

      if params[:site_id].present?
        resolve_from_site
      elsif params[:company_id].present?
        resolve_from_company
      else
        resolve_from_session_defaults
      end

      if performed?
        return
      end

      persist_context
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
    def resolve_from_site
      site    = Site.includes(:company).find_by(id: params[:site_id])
      company = @companies.find_by(id: site&.company_id)

      if company.nil?
        return reject_context("You don't have access to that site.")
      end

      if !site_scope_for(company).exists?(id: site.id)
        return reject_context("You don't have access to that site.")
      end

      @current_company      = company
      @current_company_user = current_user.company_user_for(company)
      @current_site         = site
    end

    def resolve_from_company
      @current_company = @companies.find_by(id: params[:company_id])

      if @current_company.nil?
        return reject_context("You don't have access to that company.")
      end

      @current_company_user = current_user.company_user_for(@current_company)
      @current_site         = resolve_site_for(@current_company)
    end

    def resolve_from_session_defaults
      @current_company      = resolve_company
      @current_company_user = current_user.company_user_for(@current_company)
      @current_site         = resolve_site_for(@current_company)
    end

    def persist_context
      if current_user_session.present? &&
         current_user_session.current_company_id != @current_company&.id
        current_user_session.update_column(:current_company_id, @current_company&.id)
      end

      session[:current_site_id] = @current_site&.id
    end

    def reject_context(message)
      flash[:alert] = message
      redirect_to root_path
    end

    def verify_pundit
      if response.redirect?
        return
      end

      if action_name == 'index'
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
