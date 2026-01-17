class SitePolicy < ApplicationPolicy
  def index?
    super && [
      Roleable::ROLE_IDS[:admin], Roleable::ROLE_IDS[:site_admin]
    ].include?(current_client_user&.role)
  end

  def show?
    super && [
      Roleable::ROLE_IDS[:admin], Roleable::ROLE_IDS[:site_admin]
    ].include?(current_client_user&.role)
  end

  def create?
    super && current_client_user&.admin?
  end

  def update?
    super && [
      Roleable::ROLE_IDS[:admin], Roleable::ROLE_IDS[:site_admin]
    ].include?(current_client_user&.role)
  end

  def destroy?
    super && current_client_user&.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if !active_context?
        return scope.none
      end

      sites = scope.where(client: current_client)
      case current_client_user&.role
      when Roleable::ROLE_IDS[:admin]
        sites
      when Roleable::ROLE_IDS[:site_admin], Roleable::ROLE_IDS[:manager], Roleable::ROLE_IDS[:viewer]
        sites.joins(:site_users)
          .where(site_users: { user: current_user })
          .distinct
      else
        scope.none
      end
    end
  end
end
