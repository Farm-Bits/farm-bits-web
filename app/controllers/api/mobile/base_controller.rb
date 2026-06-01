class Api::Mobile::BaseController < ActionController::API
  include Pundit::Authorization
  include ResolvesUserContext

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from MobileJwt::ExpiredError, with: :render_token_expired
  rescue_from MobileJwt::DecodeError, with: :render_unauthorized
  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  before_action :authenticate_mobile_request!
  before_action :touch_user_session
  before_action :ensure_user_has_company_access!
  before_action :resolve_company_and_site_from_url

  attr_reader :current_user, :current_user_session, :current_company,
    :current_company_user, :current_site

  def pundit_user
    {
      current_user: current_user,
      current_company: current_company,
      current_company_user: current_company_user,
      current_site: current_site
    }
  end

  protected
    def authenticate_mobile_request!
      payload = MobileJwt.decode(bearer_token)

      user_session_id = payload[:session_id]
      jti = payload[:jti]
      if user_session_id.blank? || jti.blank?
        return render_unauthorized
      end

      session = UserSession.active.find_by(id: user_session_id)
      if session.nil?
        return render_unauthorized
      end

      if !ActiveSupport::SecurityUtils.secure_compare(session.jti.to_s, jti.to_s)
        return render_unauthorized
      end

      if !session.fully_authorized?
        return render_token_otp_required(session)
      end

      authenticatable = session.authenticatable
      if authenticatable.nil? ||
        (authenticatable.respond_to?(:active?) && !authenticatable.active?)
        return render_unauthorized
      end

      @current_user_session = session
      @current_user = authenticatable
    end

    def touch_user_session
      if @current_user_session.nil?
        return
      end

      @current_user_session.touch_seen!(
        ip: request.remote_ip,
        user_agent: request.user_agent
      )
    end

    def ensure_user_has_company_access!
      if current_user.active_companies_connections.empty?
        render json: { error: 'no_company_access' }, status: :forbidden
      end
    end

    def resolve_company_and_site_from_url
      @companies = current_user.active_companies_connections

      if params[:site_id].present?
        resolve_from_site
      elsif params[:company_id].present?
        resolve_from_company
      end
    end

    def resolve_from_site
      site = Site.includes(:company).find_by(id: params[:site_id])
      company = @companies.find_by(id: site&.company_id)

      if company.nil? || !site_scope_for(company).exists?(id: site.id)
        return render json: { error: 'site_not_accessible' }, status: :forbidden
      end

      @current_company = company
      @current_company_user = current_user.company_user_for(company)
      @current_site = site
    end

    def resolve_from_company
      @current_company = @companies.find_by(id: params[:company_id])
      if @current_company.nil?
        return render json: { error: 'company_not_accessible' }, status: :forbidden
      end

      @current_company_user = current_user.company_user_for(@current_company)
    end

    def authenticated_payload(user_session, token)
      user = user_session.authenticatable
      company  = resolve_company(nil)
      site = company ? resolve_site_for(company, nil) : nil
      role = company ? user.company_user_for(company)&.role : nil
      companies = user.active_companies_connections
      sites = company ? site_scope_for(company) : Site.none

      {
        token: token,
        session: UserSessionSerializer.render_as_json(user_session, current_session_id: user_session.id),
        user: Api::Mobile::V1::UserSerializer.render_as_json(user),
        current_company: company ? Api::Mobile::V1::CompanySerializer.render_as_json(company) : nil,
        current_role: role,
        accessible_companies: Api::Mobile::V1::CompanySerializer.render_as_json(companies),
        current_site: site ? SiteSerializer.render_as_json(site, view: :with_segments) : nil,
        accessible_sites: SiteSerializer.render_as_json(sites),
        landing: {
          company_id: company&.id,
          site_id: site&.id
        }
      }
    end

    def bearer_token
      header = request.headers['Authorization'].to_s
      header.start_with?('Bearer ') ? header.delete_prefix('Bearer ') : nil
    end

    def render_unauthorized(_exception = nil)
      render json: { error: 'unauthorized' }, status: :unauthorized
    end

    def render_token_expired(_exception = nil)
      render json: { error: 'token_expired' }, status: :unauthorized
    end

    def render_token_otp_required(session)
      render json: { error: 'otp_required', session_id: session.id }, status: :unauthorized
    end

    def render_forbidden(_exception = nil)
      render json: { error: 'forbidden' }, status: :forbidden
    end

    def render_not_found(_exception = nil)
      render json: { error: 'not_found' }, status: :not_found
    end

    def render_bad_request(exception)
      render json: { error: 'bad_request', detail: exception.message }, status: :bad_request
    end
end
