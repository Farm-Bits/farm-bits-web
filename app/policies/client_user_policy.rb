class ClientUserPolicy < ApplicationPolicy
  def index?
    super
  end

  def update?
    super && [
      Roleable::ROLE_IDS[:admin],
      Roleable::ROLE_IDS[:site_admin]
    ].include?(current_client_user&.role)
  end

  def destroy?
    super && [
      Roleable::ROLE_IDS[:admin],
      Roleable::ROLE_IDS[:site_admin]
    ].include?(current_client_user&.role)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if !active_context?
        return scope.none
      end

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
