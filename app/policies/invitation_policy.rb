class InvitationPolicy < ApplicationPolicy
  def index?
    super && [
      Roleable::ROLE_IDS[:admin],
      Roleable::ROLE_IDS[:site_admin]
    ].include?(current_client_user&.role)
  end

  def create?
    super && [
      Roleable::ROLE_IDS[:admin],
      Roleable::ROLE_IDS[:site_admin]
    ].include?(current_client_user&.role)
  end

  def resend?
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
