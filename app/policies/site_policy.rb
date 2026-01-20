class SitePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    admin?
  end

  def update?
    admin? || site_admin?
  end

  def destroy?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      sites = scope.where(client: current_client)
      case current_client_user&.role
      when Roleable::ROLE_IDS[:admin]
        sites
      when Roleable::ROLE_IDS[:site_admin], Roleable::ROLE_IDS[:manager], Roleable::ROLE_IDS[:viewer]
        sites.joins(:client_user_sites)
          .where(client_user_sites: { client_user: current_client_user })
          .distinct
      else
        scope.none
      end
    end
  end
end
