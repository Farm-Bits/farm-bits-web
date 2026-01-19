class ClientUserPolicy < ApplicationPolicy
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
      site_user_ids = SiteUser.where(site: current_site).pluck(:user_id)
      scope.where(client: current_client)
        .where(
          "client_users.role = ? OR client_users.user_id IN (?)",
          Roleable::ROLE_IDS[:admin],
          site_user_ids
        )
    end
  end
end
