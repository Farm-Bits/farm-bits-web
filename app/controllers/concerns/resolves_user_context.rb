module ResolvesUserContext
  extend ActiveSupport::Concern

  private
    def current_user_session
      request.env['user_session.current.user']
    end

    # Company from an explicit hint (scoped to the user's own companies),
    # else the last-used one pinned to the session, else the first.
    def resolve_company(company_id_hint = nil)
      companies = current_user.active_companies_connections
      companies.find_by(id: company_id_hint) ||
        companies.find_by(id: current_user_session&.current_company_id) ||
        companies.first
    end

    def resolve_site_for(company, site_id_hint = session[:current_site_id])
      if company.nil?
        return nil
      end

      scoped = site_scope_for(company)
      scoped.find_by(id: site_id_hint) || scoped.first
    end

    def site_scope_for(company)
      SitePolicy::Scope.new(
        {
          current_user: current_user,
          current_company: company,
          current_company_user: current_user.company_user_for(company),
          current_site: nil
        },
        Site
      ).resolve
    end

    # The best place to send the current user.
    def user_landing_path(company_id: nil)
      company = resolve_company(company_id)
      if company.nil?
        return user_company_setup_new_path
      end

      site = resolve_site_for(company)
      if site
        user_live_path(site_id: site.id)
      else
        user_sites_path(company_id: company.id)
      end
    end
end
