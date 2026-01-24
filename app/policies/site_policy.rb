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
      sites = scope.where(company: current_company)
      case current_company_user&.role
      when Roleable::ROLE_IDS[:admin]
        sites
      when Roleable::ROLE_IDS[:site_admin], Roleable::ROLE_IDS[:manager], Roleable::ROLE_IDS[:viewer]
        sites.joins(:company_user_sites)
          .where(company_user_sites: { company_user: current_company_user })
          .distinct
      else
        scope.none
      end
    end
  end
end
