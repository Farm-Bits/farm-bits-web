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
        client_user_site_ids = policy_scope!(ClientUserSite).select(:client_user_id)
        scope.where(client: current_client)
          .where(
            "client_users.role = ? OR client_users.id IN (?)",
            Roleable::ROLE_IDS[:admin],
            client_user_site_ids
          )
      end
    end
  end
end
