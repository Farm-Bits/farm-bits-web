class SiteUserPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      site_users = scope.where(site: current_site)
      case current_client_user.role
      when 'admin'
        site_users
      when 'manager', 'viewer'
        site_ids = policy_scope!(Site).pluck(:id)
        site_users.where(site_id: site_ids)
      else
        scope.none
      end
    end
  end
end
