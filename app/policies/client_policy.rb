class ClientPolicy < ApplicationPolicy
  def create?
    super
  end

  def update?
    active_context? && record.id == current_client.id && current_client_user&.admin?
  end

  def destroy?
    active_context? && record.id == current_client.id && current_client_user&.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:client_users)
        .where(client_users: { user: current_user, active: true })
        .where(active: true)
        .distinct
    end
  end
end
