class ClientPolicy < ApplicationPolicy
  def create?
    current_user&.active
  end

  def edit?
    active_context? && record == current_client && [
      Roleable::ROLE_IDS[:admin], Roleable::ROLE_IDS[:site_admin], Roleable::ROLE_IDS[:manager]
    ].include?(current_client_user&.role)
  end

  def update?
    active_context? && record == current_client && current_client_user&.admin?
  end

  def destroy?
    active_context? && record == current_client && current_client_user&.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if !active_context?
        return scope.none
      end

      scope.joins(:client_users)
        .where(client_users: { user: current_user })
        .where(active: true)
        .distinct
    end
  end
end
