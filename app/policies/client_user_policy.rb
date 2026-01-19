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
      if admin?
        scope.where(client: current_client)
      else
        site_user_ids = policy_scope!(SiteUser).pluck(:user_id)
        scope.where(client: current_client)
          .where(
            "client_users.role = ? OR client_users.user_id IN (?)",
            Roleable::ROLE_IDS[:admin],
            site_user_ids
          )
      end
    end
  end
end
