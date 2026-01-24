class CompanyUserPolicy < ApplicationPolicy
  def index?
    true
  end

  def update?
    admin? || site_admin?
  end

  def destroy?
    admin? || site_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if admin?
        scope.where(company: current_company)
      else
        company_user_site_ids = policy_scope!(CompanyUserSite).select(:company_user_id)
        scope.where(company: current_company)
          .where(
            "company_users.role = ? OR company_users.id IN (?)",
            Roleable::ROLE_IDS[:admin],
            company_user_site_ids
          )
      end
    end
  end
end
