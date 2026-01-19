class InvitationPolicy < ApplicationPolicy
  def index?
    admin? || site_admin?
  end

  def create?
    admin? || site_admin?
  end

  def resend?
    admin? || site_admin?
  end

  def destroy?
    admin? || site_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # TODO: implement role-based access control here
      # invitation do not have site association, so we cannot filter by site
      # case current_client_user.role
      # when 'admin'
      # when 'site_admin', 'manager', 'viewer'
      #   sites = policy_scope!(Site)
      #   site_client_users.where(site: sites)
      # else
      #   scope.none
      # end

      scope.where(client: current_client)
    end
  end
end
